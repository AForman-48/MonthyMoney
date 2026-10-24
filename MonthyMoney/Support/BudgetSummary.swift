import Foundation

/// The totals block of the sheet, worked out from the monthly amounts.
struct BudgetSummary: Equatable {
    var income: Double = 0
    var essentials: Double = 0
    var nonEssentials: Double = 0
    var savings: Double = 0

    init(income: Double = 0, essentials: Double = 0, nonEssentials: Double = 0, savings: Double = 0) {
        self.income = income
        self.essentials = essentials
        self.nonEssentials = nonEssentials
        self.savings = savings
    }

    init(items: [BudgetItem]) {
        for item in items {
            switch item.category {
            case .income: income += item.amount
            case .essential: essentials += item.amount
            case .nonEssential: nonEssentials += item.amount
            case .savings: savings += item.amount
            }
        }
    }

    func total(for category: BudgetCategory) -> Double {
        switch category {
        case .income: income
        case .essential: essentials
        case .nonEssential: nonEssentials
        case .savings: savings
        }
    }

    /// Essentials, non-essentials and savings together.
    var totalExpenses: Double { essentials + nonEssentials + savings }

    var takeHome: Double { income - totalExpenses }

    /// Monthly income times the months of pay in a year (the sheet uses 14).
    func annualIncome(incomeMonths: Double) -> Double { income * incomeMonths }

    var annualExpenses: Double { totalExpenses * 12 }

    var annualTakeHome: Double { takeHome * 12 }

    var annualSavings: Double { savings * 12 }

    struct Slice: Identifiable, Equatable {
        enum Kind: String, CaseIterable {
            case essentials = "Essentials"
            case nonEssentials = "Non-Essentials"
            case savings = "Savings"
            case takeHome = "Take Home"
        }

        let kind: Kind
        let amount: Double
        let share: Double
        var id: Kind { kind }
    }

    /// The Monthly Spend pie: where each dollar of income goes. Empty or negative parts are left out.
    var spendSlices: [Slice] {
        let parts: [(Slice.Kind, Double)] = [
            (.essentials, essentials),
            (.nonEssentials, nonEssentials),
            (.savings, savings),
            (.takeHome, takeHome),
        ]
        let positive = parts.filter { $0.1 > 0 }
        let whole = positive.reduce(0) { $0 + $1.1 }
        guard whole > 0 else { return [] }
        return positive.map { Slice(kind: $0.0, amount: $0.1, share: $0.1 / whole) }
    }
}

/// The 40-year retirement projection from the sheet: each year's savings are added at the
/// start of the year and the whole balance grows by the rate of return.
enum RetirementProjection {
    struct Point: Identifiable, Equatable {
        let year: Int
        let balance: Double
        let contributed: Double
        var id: Int { year }
    }

    static func points(annualContribution: Double, rate: Double, years: Int) -> [Point] {
        guard years > 0 else { return [] }
        var balance = 0.0
        return (1...years).map { year in
            balance = (balance + annualContribution) * (1 + rate)
            return Point(year: year, balance: balance, contributed: annualContribution * Double(year))
        }
    }

    static func finalBalance(annualContribution: Double, rate: Double, years: Int) -> Double {
        points(annualContribution: annualContribution, rate: rate, years: years).last?.balance ?? 0
    }
}
