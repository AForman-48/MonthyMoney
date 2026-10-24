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
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 32) {
                    chart.frame(width: 240, height: 240)
                    legend.frame(maxWidth: 320)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 20) {
                    chart.frame(height: 240)
                    legend
                }
            }
            .padding(.vertical, 8)
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
                if let anchor = proxy.plotFrame {
                    let frame = geometry[anchor]
                    let shown = selectedSlice ?? slices.first { $0.kind == .takeHome } ?? slices[0]
                    VStack(spacing: 2) {
                        Text(shown.kind.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(shown.share.percent)
                            .font(.title2.bold())
                            .foregroundStyle(shown.kind.color)
                            .monospacedDigit()
                        Text(shown.amount.cadWhole)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .position(x: frame.midX, y: frame.midY)
                }
            }
        }
        .animation(.snappy, value: selectedSlice)
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(slices) { slice in
                HStack(spacing: 10) {
                    Circle()
                        .fill(slice.kind.color)
                        .frame(width: 10, height: 10)
                    Text(slice.kind.rawValue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                    Text(slice.share.percent)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Text(slice.amount.cad)
                        .monospacedDigit()
                        .frame(minWidth: 90, alignment: .trailing)
                }
                .font(.subheadline)
                .accessibilityElement(children: .combine)
            }
        }
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
