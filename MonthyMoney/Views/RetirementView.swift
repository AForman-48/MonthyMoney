import Charts
import SwiftData
import SwiftUI

/// The Retirement Savings chart from the sheet: the yearly savings invested at a fixed
/// rate of return, compounded every year.
struct RetirementView: View {
    @Query private var items: [BudgetItem]
    @AppStorage(BudgetSettings.returnRateKey) private var returnRate = BudgetSettings.defaultReturnRate
    @AppStorage(BudgetSettings.yearsKey) private var years = BudgetSettings.defaultYears
    @AppStorage(BudgetSettings.usesAgeKey) private var usesAge = false
    @AppStorage(BudgetSettings.startAgeKey) private var startAge = BudgetSettings.defaultStartAge
    /// The chart position being scrubbed, as a year or an age depending on `usesAge`.
    @State private var selectedX: Int?

    private var annualSavings: Double { BudgetSummary(items: items).annualSavings }

    private var points: [RetirementProjection.Point] {
        RetirementProjection.points(annualContribution: annualSavings, rate: returnRate, years: years)
    }

    /// Where a year sits on the chart: the year itself, or the age in that year.
    private func x(for year: Int) -> Int { usesAge ? startAge + year - 1 : year }

    /// "Year 12" or "Age 41".
    private func label(for year: Int) -> String { usesAge ? "Age \(startAge + year - 1)" : "Year \(year)" }

    private var selectedPoint: RetirementProjection.Point? {
        guard let selectedX else { return nil }
        return points.first { x(for: $0.year) == selectedX }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    let shown = selectedPoint ?? points.last
                    VStack(alignment: .leading, spacing: 4) {
                        Text(shown.map { usesAge ? "By age \(startAge + $0.year - 1)" : "After \($0.year == 1 ? "1 year" : "\($0.year) years")" } ?? "Retirement Savings")
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
                    SliderRow(title: "Rate of Return", value: returnRate.percent) {
                        Slider(value: $returnRate, in: 0...0.15, step: 0.005)
                    }
                    SliderRow(title: "Years", value: "\(years)") {
                        Slider(value: intBinding($years), in: 1...60, step: 1)
                    }
                } header: {
                    Text("Assumptions")
                } footer: {
                    Text("Saved Each Year is your monthly Savings total times 12. Each year's savings are added and the balance grows by the rate of return.")
                }

                Section {
                    Toggle("Track by Age", isOn: $usesAge.animation())
                    if usesAge {
                        Stepper(value: $startAge, in: 14...90) {
                            LabeledContent("Age in Year 1") {
                                Text("\(startAge)").monospacedDigit()
                            }
                        }
                    }
                } header: {
                    Text("Age")
                } footer: {
                    if usesAge {
                        Text("Year 1 is age \(startAge), so year \(years) is age \(startAge + years - 1).")
                    } else {
                        Text("Label the chart by your age instead of the year.")
                    }
                }

                Section("Milestones") {
                    ForEach(points.filter { $0.year % 5 == 0 || $0.year == years }) { point in
                        LabeledContent(label(for: point.year)) {
                            Text(point.balance.cad).monospacedDigit()
                        }
                    }
                }
            }
            .navigationTitle("Retirement")
            .tint(.retirement)
        }
    }

    /// Lets a Slider, which works in Doubles, drive a whole-number setting.
    private func intBinding(_ binding: Binding<Int>) -> Binding<Double> {
        Binding(get: { Double(binding.wrappedValue) }, set: { binding.wrappedValue = Int($0.rounded()) })
    }

    private var chart: some View {
        Chart(points) { point in
            AreaMark(
                x: .value(usesAge ? "Age" : "Year", x(for: point.year)),
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
                x: .value(usesAge ? "Age" : "Year", x(for: point.year)),
                y: .value("Balance", point.balance)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(Color.retirement)
            .lineStyle(StrokeStyle(lineWidth: 2.5))

            if let selectedPoint, selectedPoint.year == point.year {
                RuleMark(x: .value(usesAge ? "Age" : "Year", x(for: point.year)))
                    .foregroundStyle(Color.secondary.opacity(0.5))
                PointMark(
                    x: .value(usesAge ? "Age" : "Year", x(for: point.year)),
                    y: .value("Balance", point.balance)
                )
                .foregroundStyle(Color.retirement)
                .symbolSize(80)
            }
        }
        .chartXSelection(value: $selectedX)
        .chartXScale(domain: x(for: 1)...x(for: max(years, 2)))
        .chartXAxisLabel(usesAge ? "Age" : "Year")
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
        .accessibilityLabel("Retirement savings by \(usesAge ? "age" : "year")")
    }
}

/// A setting with its current value on the first line and a slider under it.
struct SliderRow<Control: View>: View {
    let title: String
    let value: String
    @ViewBuilder let control: Control

    var body: some View {
        VStack(spacing: 6) {
            LabeledContent(title) {
                Text(value).monospacedDigit()
            }
            control
                .accessibilityLabel(title)
                .accessibilityValue(value)
        }
    }
}

#Preview {
    RetirementView()
        .modelContainer(PreviewData.container)
}
