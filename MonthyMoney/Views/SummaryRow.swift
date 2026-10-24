import SwiftUI

/// One line of the totals block, with the figure in the block's colour.
struct SummaryRow: View {
    let title: String
    let value: Double
    let systemImage: String
    let color: Color

    var body: some View {
        LabeledContent {
            Text(value.cad)
                .monospacedDigit()
                .foregroundStyle(value < 0 ? Color.overspent : Color.primary)
                .contentTransition(.numericText(value: value))
        } label: {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage).foregroundStyle(color)
            }
        }
    }
}
