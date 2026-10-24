import Foundation
import SwiftData

enum SeedData {
    /// The pay methods used by the sample budget. New installs start with none.
    static let samplePayMethods: [(String, PayMethodColor)] = [
        ("WFCU Chqing", .navy),
        ("Tangerine MC", .orange),
        ("TD Visa", .forest),
        ("TD Chqing", .green),
        ("Capital One", .red),
        ("Various", .gray),
    ]

    @discardableResult
    static func insertPayMethods(into context: ModelContext) -> [String: PayMethod] {
        var methods: [String: PayMethod] = [:]
        for (index, entry) in samplePayMethods.enumerated() {
            let method = PayMethod(name: entry.0, color: entry.1, sortOrder: index)
            context.insert(method)
            methods[entry.0] = method
        }
        return methods
    }

    /// Example budget for previews and screenshots. The amounts are made up.
    static func insertSample(into context: ModelContext) {
        let methods = insertPayMethods(into: context)
        let rows: [(String, Double, BudgetCategory, String?)] = [
            ("Paycheque", 4200, .income, nil),
            ("Rent", 1350, .essential, "WFCU Chqing"),
            ("Phone", 45, .essential, "Tangerine MC"),
            ("Internet", 75, .essential, "Tangerine MC"),
            ("Car Insurance", 120, .essential, "Tangerine MC"),
            ("Gas", 180, .essential, "Tangerine MC"),
            ("Groceries", 450, .essential, "Tangerine MC"),
            ("Bank Fee", 4, .essential, "TD Chqing"),
            ("Gym", 55, .nonEssential, "WFCU Chqing"),
            ("Streaming", 22, .nonEssential, "TD Visa"),
            ("Game Pass", 29, .nonEssential, "TD Visa"),
            ("RRSP", 300, .savings, "WFCU Chqing"),
            ("TFSA", 500, .savings, "WFCU Chqing"),
        ]
        var orders: [BudgetCategory: Int] = [:]
        for row in rows {
            let order = orders[row.2, default: 0]
            orders[row.2] = order + 1
            context.insert(BudgetItem(name: row.0, amount: row.1, category: row.2, payMethod: row.3.flatMap { methods[$0] }, sortOrder: order))
        }
        try? context.save()
    }

    static func insertSampleIfEmpty(into context: ModelContext) {
        guard ((try? context.fetchCount(FetchDescriptor<BudgetItem>())) ?? 0) == 0 else { return }
        for method in (try? context.fetch(FetchDescriptor<PayMethod>())) ?? [] { context.delete(method) }
        insertSample(into: context)
    }
}
