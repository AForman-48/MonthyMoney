import Foundation
import Observation

/// Display preferences read by formatting code outside any view. It's observable, so every view
/// that formats an amount redraws when a preference changes.
@Observable
final class DisplaySettings {
    static let shared = DisplaySettings()

    /// Whether amounts show cents. When off they're rounded to the nearest dollar for display only;
    /// the stored amounts keep their cents.
    var showsDecimals: Bool {
        didSet { UserDefaults.standard.set(showsDecimals, forKey: BudgetSettings.showsDecimalsKey) }
    }

    private init() {
        let defaults = UserDefaults.standard
        showsDecimals = defaults.object(forKey: BudgetSettings.showsDecimalsKey) == nil
            ? BudgetSettings.defaultShowsDecimals
            : defaults.bool(forKey: BudgetSettings.showsDecimalsKey)
    }
}
