import Charts
import SwiftData
import SwiftUI

/// The Retirement Savings chart from the sheet: the yearly savings invested at a fixed
/// rate of return, compounded every year.
struct RetirementView: View {
    @Query private var items: [BudgetItem]
    @AppStorage(BudgetSettings.returnRateKey) private var returnRate = BudgetSettings.defaultReturnRate
    @AppStorage(BudgetSettings.yearsKey) private var years = BudgetSettings.defaultYears
    @State private var selectedYear: Int?

    private var annualSavings: Double { BudgetSummary(items: items).annualSavings }

    private var points: [RetirementProjection.Point] {
        RetirementProjection.points(annualContribution: annualSavings, rate: returnRate, years: years)
    }

    private var selectedPoint: RetirementProjection.Point? {
        guard let selectedYear else { return nil }
        return points.first { $0.year == selectedYear }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    let shown = selectedPoint ?? points.last
                    VStack(alignment: .leading, spacing: 4) {
                        Text(shown.map { "After \($0.year == 1 ? "1 year" : "\($0.year) years")" } ?? "Retirement Savings")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text((shown?.balance ?? 0).cad)
                            .font(.largeTitle.bold())
                            .monospacedDigit()
                            .foregroundStyle(Color.retirement)
                            .contentTransition(.numericText(value: shown?.balance ?? 0))
                        Text("\((shown?.contributed ?? 0).cadWhole) saved, \(((shown?.balance ?? 0) - (shown?.contributed ?? 0)).cadWhole) growth")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    chart
                }

                Section {
                    LabeledContent("Saved Each Year") {
                        Text(annualSavings.cad).monospacedDigit()
                    }
                    Stepper(value: $returnRate, in: 0...0.20, step: 0.005) {
                        LabeledContent("Rate of Return") {
                            Text(returnRate.percent).monospacedDigit()
                        }
                    }
                    Stepper(value: $years, in: 1...60) {
                        LabeledContent("Years") {
                            Text("\(years)").monospacedDigit()
                        }
                    }
                } header: {
                    Text("Assumptions")
                } footer: {
                    Text("Saved Each Year is your monthly Savings total times 12. Each year's savings are added and the balance grows by the rate of return.")
                }

                Section("Milestones") {
                    ForEach(points.filter { $0.year % 5 == 0 || $0.year == years }) { point in
                        LabeledContent("Year \(point.year)") {
                            Text(point.balance.cad).monospacedDigit()
                        }
                    }
                }
            }
            .navigationTitle("Retirement")
            .tint(.retirement)
        }
    }

    private var chart: some View {
        Chart(points) { point in
            AreaMark(
                x: .value("Year", point.year),
                y: .value("Balance", point.balance)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.retirement.opacity(0.4), Color.retirement.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            LineMark(
                x: .value("Year", point.year),
                y: .value("Balance", point.balance)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(Color.retirement)
            .lineStyle(StrokeStyle(lineWidth: 2.5))

            if let selectedPoint, selectedPoint.year == point.year {
                RuleMark(x: .value("Year", point.year))
                    .foregroundStyle(Color.secondary.opacity(0.5))
                PointMark(
                    x: .value("Year", point.year),
                    y: .value("Balance", point.balance)
                )
                .foregroundStyle(Color.retirement)
                .symbolSize(80)
            }
        }
        .chartXSelection(value: $selectedYear)
        .chartXScale(domain: 1...max(years, 2))
        .chartXAxisLabel("Year")
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(amount, format: .currency(code: "CAD").notation(.compactName))
                    }
                }
            }
        }
        .frame(height: 260)
        .accessibilityLabel("Retirement savings by year")
    }
}

#Preview {
    RetirementView()
        .modelContainer(PreviewData.container)
}
