import Charts
import SwiftData
import SwiftUI

struct SummaryView: View {
    @Query private var items: [BudgetItem]
    @Query(sort: [SortDescriptor(\PayMethod.sortOrder), SortDescriptor(\PayMethod.name)]) private var payMethods: [PayMethod]
    @AppStorage(BudgetSettings.incomeMonthsKey) private var incomeMonths = BudgetSettings.defaultIncomeMonths
    @AppStorage(BudgetSettings.returnRateKey) private var returnRate = BudgetSettings.defaultReturnRate
    @AppStorage(BudgetSettings.yearsKey) private var years = BudgetSettings.defaultYears

    private var summary: BudgetSummary { BudgetSummary(items: items) }

    private var usedPayMethods: [PayMethod] {
        payMethods.filter { $0.monthlyTotal > 0 }.sorted { $0.monthlyTotal > $1.monthlyTotal }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Take Home")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(summary.takeHome.cad)
                            .font(.largeTitle.bold())
                            .monospacedDigit()
                            .foregroundStyle(summary.takeHome >= 0 ? Color.income : Color.retirement)
                            .contentTransition(.numericText(value: summary.takeHome))
                        Text("each month after expenses and savings")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    SummaryRow(title: "Total Income", value: summary.income, systemImage: "banknote", color: .income)
                    SummaryRow(title: "Total Expenses", value: summary.totalExpenses, systemImage: "cart", color: .income)
                    SummaryRow(title: "Take Home", value: summary.takeHome, systemImage: "arrow.down.circle", color: .income)
                } header: {
                    Text("Monthly")
                }

                Section {
                    MonthlySpendChart(slices: summary.spendSlices)
                } header: {
                    Text("Monthly Spend")
                } footer: {
                    if summary.takeHome < 0 {
                        Text("You're spending \((-summary.takeHome).cad) more than you earn each month.")
                    }
                }

                Section {
                    SummaryRow(title: "Annual Income", value: summary.annualIncome(incomeMonths: incomeMonths), systemImage: "banknote", color: .annual)
                    SummaryRow(title: "Annual Expenses", value: summary.annualExpenses, systemImage: "cart", color: .annual)
                    SummaryRow(title: "Annual Take Home", value: summary.annualTakeHome, systemImage: "arrow.down.circle", color: .annual)
                    SummaryRow(title: "Annual Savings", value: summary.annualSavings, systemImage: "building.columns", color: .annual)
                } header: {
                    Text("Annual")
                } footer: {
                    Text("Annual Income counts \(incomeMonths.formatted()) months of pay; the others count 12. Change this in Settings.")
                }

                Section("Retirement") {
                    SummaryRow(
                        title: "Retirement Savings",
                        value: RetirementProjection.finalBalance(annualContribution: summary.annualSavings, rate: returnRate, years: years),
                        systemImage: "chart.line.uptrend.xyaxis",
                        color: .retirement
                    )
                }

                if !usedPayMethods.isEmpty {
                    Section {
                        ForEach(usedPayMethods) { method in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    PayMethodBadge(method: method)
                                    Spacer()
                                    Text(method.monthlyTotal.cad)
                                        .monospacedDigit()
                                }
                                ProgressView(value: method.monthlyTotal, total: max(summary.totalExpenses, 0.01))
                                    .tint(method.color.color)
                                    .accessibilityHidden(true)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    } header: {
                        Text("By Pay Method")
                    } footer: {
                        Text("What comes out of each account or card every month.")
                    }
                }
            }
            .navigationTitle("Summary")
            .overlay {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No Budget Yet",
                        systemImage: "chart.pie",
                        description: Text("Add your income and monthly expenses on the Budget tab.")
                    )
                }
            }
        }
    }
}

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
                .foregroundStyle(value < 0 ? Color.retirement : Color.primary)
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

#Preview {
    SummaryView()
        .modelContainer(PreviewData.container)
}
