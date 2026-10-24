import Foundation
import SwiftData
import Testing
@testable import MonthyMoney

struct BudgetSummaryTests {
    /// The figures from the budget spreadsheet.
    let sheet = BudgetSummary(income: 4000, essentials: 2157.66, nonEssentials: 157.01, savings: 830)

    @Test func monthlyTotalsMatchTheSheet() {
        #expect(abs(sheet.totalExpenses - 3144.67) < 0.001)
        #expect(abs(sheet.takeHome - 855.33) < 0.001)
    }

    @Test func annualTotalsMatchTheSheet() {
        #expect(sheet.annualIncome(incomeMonths: 14) == 56000)
        #expect(abs(sheet.annualExpenses - 37736.04) < 0.001)
        #expect(abs(sheet.annualTakeHome - 10263.96) < 0.001)
        #expect(abs(sheet.annualSavings - 9960) < 0.001)
    }

    @Test func spendSlicesMatchTheSheetPie() {
        let shares = Dictionary(uniqueKeysWithValues: sheet.spendSlices.map { ($0.kind, $0.share) })
        #expect(abs(shares[.essentials]! - 0.539) < 0.001)
        #expect(abs(shares[.nonEssentials]! - 0.039) < 0.001)
        #expect(abs(shares[.savings]! - 0.208) < 0.001)
        #expect(abs(shares[.takeHome]! - 0.214) < 0.001)
    }

    @Test func overspendingLeavesTakeHomeOutOfThePie() {
        let summary = BudgetSummary(income: 1000, essentials: 900, nonEssentials: 300, savings: 0)
        #expect(summary.takeHome == -200)
        #expect(summary.spendSlices.map(\.kind) == [.essentials, .nonEssentials])
    }

    @Test func emptyBudgetHasNoSlices() {
        #expect(BudgetSummary().spendSlices.isEmpty)
    }
}

struct RetirementProjectionTests {
    @Test func firstYearGrowsTheContribution() {
        let points = RetirementProjection.points(annualContribution: 9960, rate: 0.10, years: 2)
        #expect(abs(points[0].balance - 10956) < 0.001)
        #expect(abs(points[1].balance - (10956 + 9960) * 1.1) < 0.001)
    }

    @Test func fortyYearsMatchesTheAnnuityFormula() {
        // Each year's savings grow for the remaining years: S × 1.1 × (1.1^40 − 1) / 0.1.
        let expected = 9960 * 1.1 * (pow(1.1, 40) - 1) / 0.1
        let balance = RetirementProjection.finalBalance(annualContribution: 9960, rate: 0.10, years: 40)
        #expect(abs(balance - expected) < 0.01)
        #expect(RetirementProjection.points(annualContribution: 9960, rate: 0.10, years: 40).count == 40)
    }

    @Test func noYearsHasNoPoints() {
        #expect(RetirementProjection.points(annualContribution: 1000, rate: 0.1, years: 0).isEmpty)
    }
}

@MainActor
struct StoreTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([BudgetItem.self, PayMethod.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return ModelContext(try ModelContainer(for: schema, configurations: configuration))
    }

    @Test func summaryAddsItemsByCategory() throws {
        let context = try makeContext()
        context.insert(BudgetItem(name: "Pay", amount: 4000, category: .income))
        context.insert(BudgetItem(name: "Rent", amount: 1210, category: .essential))
        context.insert(BudgetItem(name: "Food", amount: 450, category: .essential))
        context.insert(BudgetItem(name: "Gym", amount: 60, category: .nonEssential))
        context.insert(BudgetItem(name: "TFSA", amount: 530, category: .savings))
        let summary = BudgetSummary(items: try context.fetch(FetchDescriptor<BudgetItem>()))
        #expect(summary == BudgetSummary(income: 4000, essentials: 1660, nonEssentials: 60, savings: 530))
    }

    @Test func payMethodTotalCountsItsExpenses() throws {
        let context = try makeContext()
        let card = PayMethod(name: "TD Visa", color: .forest)
        context.insert(card)
        context.insert(BudgetItem(name: "Game Pass", amount: 29.37, category: .nonEssential, payMethod: card))
        context.insert(BudgetItem(name: "Stack TV", amount: 16.94, category: .nonEssential, payMethod: card))
        try context.save()
        #expect(abs(card.monthlyTotal - 46.31) < 0.001)
    }

    @Test func nextSortOrderIsPerCategory() throws {
        let context = try makeContext()
        context.insert(BudgetItem(name: "Rent", amount: 1, category: .essential, sortOrder: 0))
        context.insert(BudgetItem(name: "Gas", amount: 1, category: .essential, sortOrder: 1))
        try context.save()
        #expect(BudgetItem.nextSortOrder(for: .essential, in: context) == 2)
        #expect(BudgetItem.nextSortOrder(for: .savings, in: context) == 0)
    }

    @Test func duplicatePayMethodsAreMerged() throws {
        let context = try makeContext()
        let first = PayMethod(name: "TD Visa", color: .forest)
        first.createdAt = .distantPast
        let second = PayMethod(name: "td visa", color: .blue)
        context.insert(first)
        context.insert(second)
        let item = BudgetItem(name: "Stack TV", amount: 16.94, category: .nonEssential, payMethod: second)
        context.insert(item)
        try context.save()

        SyncCleanup.mergeDuplicates(in: context)

        let methods = try context.fetch(FetchDescriptor<PayMethod>())
        #expect(methods.count == 1)
        #expect(item.payMethod === first)
    }
}
