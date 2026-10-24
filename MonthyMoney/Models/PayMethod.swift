import Foundation
import SwiftData

/// An account or card that a bill comes out of, like the Pay Method column of the sheet.
@Model
final class PayMethod {
    var name: String = ""
    var colorRaw: String = PayMethodColor.blue.rawValue
    var sortOrder: Int = 0
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .nullify, inverse: \BudgetItem.payMethod)
    var items: [BudgetItem]? = []

    init(name: String, color: PayMethodColor, sortOrder: Int = 0) {
        self.name = name
        self.colorRaw = color.rawValue
        self.sortOrder = sortOrder
    }

    var color: PayMethodColor {
        get { PayMethodColor(rawValue: colorRaw) ?? .blue }
        set { colorRaw = newValue.rawValue }
    }

    /// The monthly total of the expenses paid this way.
    var monthlyTotal: Double {
        (items ?? []).filter { $0.category.usesPayMethod }.reduce(0) { $0 + $1.amount }
    }

    static func nextSortOrder(in context: ModelContext) -> Int {
        var descriptor = FetchDescriptor<PayMethod>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
        descriptor.fetchLimit = 1
        let last = (try? context.fetch(descriptor))?.first?.sortOrder ?? -1
        return last + 1
    }
}
