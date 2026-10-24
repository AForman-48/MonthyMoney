import Foundation
import SwiftData

// Every attribute has a default and relationships are optional so the schema
// stays compatible with CloudKit.
@Model
final class BudgetItem {
    var name: String = ""
    /// The monthly amount in CAD.
    var amount: Double = 0
    var categoryRaw: String = BudgetCategory.essential.rawValue
    var notes: String = ""
    /// Position within its category. Lower comes first; ties fall back to the name.
    var sortOrder: Int = 0
    var createdAt: Date = Date.now
    var payMethod: PayMethod?
    /// An SF Symbol shown beside the name, in the category's colour.
    var symbolName: String?

    init(name: String, amount: Double, category: BudgetCategory, payMethod: PayMethod? = nil, sortOrder: Int = 0) {
        self.name = name
        self.amount = amount
        self.categoryRaw = category.rawValue
        self.payMethod = payMethod
        self.sortOrder = sortOrder
    }

    var category: BudgetCategory {
        get { BudgetCategory(rawValue: categoryRaw) ?? .essential }
        set { categoryRaw = newValue.rawValue }
    }

    /// The sort order that places a new item last in its category.
    static func nextSortOrder(for category: BudgetCategory, in context: ModelContext) -> Int {
        let raw = category.rawValue
        var descriptor = FetchDescriptor<BudgetItem>(
            predicate: #Predicate { $0.categoryRaw == raw },
            sortBy: [SortDescriptor(\.sortOrder, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let last = (try? context.fetch(descriptor))?.first?.sortOrder ?? -1
        return last + 1
    }

    /// Items in display order: by sort order, then by name.
    static func sorted(_ items: [BudgetItem]) -> [BudgetItem] {
        items.sorted {
            if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }
}
