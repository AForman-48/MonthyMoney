import SwiftUI

/// The four columns of the budget sheet. Every amount is monthly.
enum BudgetCategory: String, CaseIterable, Identifiable {
    case income, essential, nonEssential, savings

    var id: Self { self }

    var title: String {
        switch self {
        case .income: "Income"
        case .essential: "Essentials"
        case .nonEssential: "Non-Essentials"
        case .savings: "Savings"
        }
    }

    /// The name for one entry, used in "Add …" buttons and editor titles.
    var singularTitle: String {
        switch self {
        case .income: "Income"
        case .essential: "Essential"
        case .nonEssential: "Non-Essential"
        case .savings: "Savings"
        }
    }

    var systemImage: String {
        switch self {
        case .income: "banknote"
        case .essential: "house"
        case .nonEssential: "sparkles"
        case .savings: "building.columns"
        }
    }

    var color: Color {
        switch self {
        case .income: Color.income
        case .essential: Color.essentials
        case .nonEssential: Color.nonEssentials
        case .savings: Color.savings
        }
    }

    /// Income has no pay method; every other column does.
    var usesPayMethod: Bool { self != .income }
}
