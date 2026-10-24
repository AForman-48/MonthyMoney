import Charts
import SwiftUI

/// The Monthly Spend pie from the sheet: how income splits between essentials,
/// non-essentials, savings and take home.
struct MonthlySpendChart: View {
    let slices: [BudgetSummary.Slice]

    @State private var selectedAmount: Double?

    private var selectedSlice: BudgetSummary.Slice? {
        guard let selectedAmount else { return nil }
        var running = 0.0
        for slice in slices {
            running += slice.amount
            if selectedAmount <= running { return slice }
        }
        return nil
    }

    var body: some View {
        if slices.isEmpty {
            Text("Add income and expenses to see where your money goes.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 120)
        } else {
            chart
                .frame(height: 320)
                .padding(.vertical, 12)
        }
    }

    private var chart: some View {
        Chart(slices) { slice in
            SectorMark(
                angle: .value("Amount", slice.amount),
                innerRadius: .ratio(0.6),
                outerRadius: .ratio(selectedSlice == nil || selectedSlice == slice ? 1 : 0.92),
                angularInset: 1.5
            )
            .cornerRadius(5)
            .foregroundStyle(slice.kind.color)
            .accessibilityLabel(slice.kind.rawValue)
            .accessibilityValue("\(slice.amount.cad), \(slice.share.percent)")
        }
        .chartAngleSelection(value: $selectedAmount)
        .chartBackground { proxy in
            GeometryReader { geometry in
                // The category shows only while its slice is being touched.
                if let anchor = proxy.plotFrame, let shown = selectedSlice {
                    let frame = geometry[anchor]
                    VStack(spacing: 2) {
                        Text(shown.kind.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(shown.share.percent)
                            .font(.largeTitle.bold())
                            .foregroundStyle(shown.kind.color)
                            .monospacedDigit()
                        Text(shown.amount.cadWhole)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .position(x: frame.midX, y: frame.midY)
                }
            }
        }
        .animation(.snappy, value: selectedSlice)
    }
}

extension BudgetSummary.Slice.Kind {
    var color: Color {
        switch self {
        case .essentials: .essentials
        case .nonEssentials: .nonEssentials
        case .savings: .savings
        case .takeHome: .income
        }
    }
}

#Preview {
    List {
        MonthlySpendChart(slices: BudgetSummary(income: 4000, essentials: 2157.66, nonEssentials: 157.01, savings: 830).spendSlices)
    }
}
