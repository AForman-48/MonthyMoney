import Foundation

/// iCloud sync. The budget items and pay methods sync through SwiftData's CloudKit store,
/// and the settings through iCloud key-value storage (`SettingsSync`).
enum CloudSync {
    static let containerIdentifier = "iCloud.ca.aforman.MonthyMoney"

    /// Set from the CODE_SIGNING_ALLOWED build setting through Info.plist. Unsigned builds carry
    /// no iCloud entitlement, and CloudKit traps at launch without one, so they don't sync.
    static var isEnabled: Bool {
        (Bundle.main.object(forInfoDictionaryKey: "CloudKitSyncEnabled") as? String) != "NO"
    }
}

/// Keeps the budget settings the same on every device by mirroring them between UserDefaults,
/// where the app reads them, and iCloud key-value storage. Appearance stays per device.
@MainActor
final class SettingsSync {
    static let shared = SettingsSync()

    static let syncedKeys = [
        BudgetSettings.paychequesKey,
        BudgetSettings.returnRateKey,
        BudgetSettings.yearsKey,
        BudgetSettings.usesAgeKey,
        BudgetSettings.startAgeKey,
        BudgetSettings.showsPayMethodsKey,
        BudgetSettings.showsDecimalsKey,
        BudgetSettings.hasCompletedWalkthroughKey,
    ]

    private let store = NSUbiquitousKeyValueStore.default
    private let defaults = UserDefaults.standard
    private var observers: [NSObjectProtocol] = []
    private var isApplyingRemote = false

    /// Starts syncing. Settings already in iCloud win over this device's; settings only this
    /// device has are uploaded.
    func start() {
        guard CloudSync.isEnabled, observers.isEmpty else { return }
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: store, queue: .main) { [weak self] notification in
            let keys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]
            MainActor.assumeIsolated { self?.applyRemote(keys ?? Self.syncedKeys) }
        })
        observers.append(center.addObserver(forName: UserDefaults.didChangeNotification, object: defaults, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.pushLocal() }
        })
        store.synchronize()
        applyRemote(Self.syncedKeys)
        pushLocal()
    }

    /// Copies settings that changed in iCloud into UserDefaults.
    private func applyRemote(_ keys: [String]) {
        isApplyingRemote = true
        defer { isApplyingRemote = false }
        for key in keys where Self.syncedKeys.contains(key) {
            guard let value = store.object(forKey: key) else { continue }
            // Finishing the walkthrough on one device finishes it everywhere, never the reverse.
            if key == BudgetSettings.hasCompletedWalkthroughKey && (value as? Bool) != true { continue }
            if !Self.isEqual(defaults.object(forKey: key), value) {
                defaults.set(value, forKey: key)
            }
        }
        // Formatting reads this outside any view, so it has its own observable copy.
        if let showsDecimals = store.object(forKey: BudgetSettings.showsDecimalsKey) as? Bool,
           DisplaySettings.shared.showsDecimals != showsDecimals {
            DisplaySettings.shared.showsDecimals = showsDecimals
        }
    }

    /// Uploads settings changed on this device. Only values the app saved are sent, not launch arguments.
    private func pushLocal() {
        guard !isApplyingRemote, let bundleID = Bundle.main.bundleIdentifier else { return }
        let saved = defaults.persistentDomain(forName: bundleID) ?? [:]
        for key in Self.syncedKeys {
            guard let value = saved[key] else { continue }
            if key == BudgetSettings.hasCompletedWalkthroughKey && (value as? Bool) != true { continue }
            if !Self.isEqual(store.object(forKey: key), value) {
                store.set(value, forKey: key)
            }
        }
    }

    private static func isEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
        guard let lhs = lhs as? NSObject, let rhs = rhs as? NSObject else { return lhs == nil && rhs == nil }
        return lhs.isEqual(rhs)
    }
}
