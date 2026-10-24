import Foundation

extension Double {
    /// Formats the value as Canadian dollars, with or without cents as set in Settings.
    var cad: String {
        cad(showsDecimals: DisplaySettings.shared.showsDecimals)
    }

    /// Canadian dollars, or rounded to the nearest whole dollar when `showsDecimals` is off.
    func cad(showsDecimals: Bool) -> String {
        showsDecimals ? formatted(.currency(code: "CAD")) : cadWhole
    }

    /// Whole Canadian dollars, for chart axes and large figures.
    var cadWhole: String {
        formatted(.currency(code: "CAD").precision(.fractionLength(0)).rounded(rule: .toNearestOrAwayFromZero))
    }

    var percent: String {
        formatted(.percent.precision(.fractionLength(0...1)))
    }
}
