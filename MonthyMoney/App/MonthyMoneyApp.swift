import SwiftData
import SwiftUI

@main
struct MonthyMoneyApp: App {
    let container: ModelContainer
    @AppStorage(AppAppearance.storageKey) private var appearance: AppAppearance = .system

    init() {
        #if DEBUG
        CloudKitSchema.initializeIfRequested()
        #endif
        let schema = Schema([BudgetItem.self, PayMethod.self])
        // Syncs through the user's private iCloud database. Without iCloud the store still works locally.
        // Unsigned builds (CODE_SIGNING_ALLOWED=NO) carry no iCloud entitlement, and CloudKit traps
        // at launch without one, so those builds use a local-only store.
        let configuration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: Self.cloudKitSyncEnabled ? .private("iCloud.ca.aforman.MonthyMoney") : .none
        )
        do {
            container = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Could not open the MonthyMoney store: \(error)")
        }
        #if DEBUG
        // For App Store screenshots: launch with -seedSampleData to fill an empty store.
        if CommandLine.arguments.contains("-seedSampleData") {
            SeedData.insertSampleIfEmpty(into: container.mainContext)
            UserDefaults.standard.set(true, forKey: BudgetSettings.hasCompletedWalkthroughKey)
        }
        #endif
        SyncCleanup.mergeDuplicates(in: container.mainContext)
    }

    /// Set from the CODE_SIGNING_ALLOWED build setting through Info.plist.
    private static var cloudKitSyncEnabled: Bool {
        (Bundle.main.object(forInfoDictionaryKey: "CloudKitSyncEnabled") as? String) != "NO"
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                // Set at the root so sheets follow it too.
                .preferredColorScheme(appearance.colorScheme)
        }
        .modelContainer(container)
    }
}
