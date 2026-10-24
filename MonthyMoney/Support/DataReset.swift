import Foundation
import SwiftData

/// Clears the store.
enum DataReset {
    /// Removes every budget item. Pay methods are kept unless `includingPayMethods` is set.
    static func deleteAll(includingPayMethods: Bool, in context: ModelContext) {
        // Deleted one by one rather than as a batch so iCloud sync sees each deletion.
        for item in (try? context.fetch(FetchDescriptor<BudgetItem>())) ?? [] { context.delete(item) }
        if includingPayMethods {
            for method in (try? context.fetch(FetchDescriptor<PayMethod>())) ?? [] { context.delete(method) }
        }
        try? context.save()
    }
}
