#if DEBUG
import Foundation

/// Launch arguments for App Store screenshots, Debug builds only:
/// `-screenshotScreen budget|summary|retirement|settings`
/// (usually together with `-seedSampleData`).
enum ScreenshotMode {
    static var screen: String? { UserDefaults.standard.string(forKey: "screenshotScreen") }
}
#endif
