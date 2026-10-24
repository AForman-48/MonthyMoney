import Foundation

extension Double {
    /// Formats the value as Canadian dollars.
    var cad: String {
        formatted(.currency(code: "CAD"))
    }

    /// Whole Canadian dollars, for chart axes and large figures.
    var cadWhole: String {
        formatted(.currency(code: "CAD").precision(.fractionLength(0)))
    }

    var percent: String {
        formatted(.percent.precision(.fractionLength(0...1)))
    }
}
