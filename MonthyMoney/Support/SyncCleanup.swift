import Foundation
import SwiftData

/// If two devices both add the default pay methods before they sync, the names appear twice.
/// Pay methods with the same name are merged, keeping the oldest and moving items onto it.
enum SyncCleanup {
    static func mergeDuplicates(in context: ModelContext) {
        let descriptor = FetchDescriptor<PayMethod>(sortBy: [SortDescriptor(\.createdAt)])
        guard let methods = try? context.fetch(descriptor) else { return }
        var kept: [String: PayMethod] = [:]
        var changed = false
        for method in methods {
            let key = method.name.trimmingCharacters(in: .whitespaces).lowercased()
            guard let keeper = kept[key] else {
                kept[key] = method
                continue
            }
            for item in method.items ?? [] { item.payMethod = keeper }
            context.delete(method)
            changed = true
        }
        if changed { try? context.save() }
    }
}
