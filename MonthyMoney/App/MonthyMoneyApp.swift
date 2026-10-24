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
        let configuration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: CloudSync.isEnabled ? .private(CloudSync.containerIdentifier) : .none
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
        SettingsSync.shared.start()
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
