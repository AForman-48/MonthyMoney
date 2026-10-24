import Charts
import SwiftData
import SwiftUI

/// The first page of the budget spreadsheet on one screen: the four columns, the totals
/// and annual blocks, retirement savings, the Monthly Spend pie and the retirement chart.
struct SheetView: View {
    @Query private var items: [BudgetItem]
    @AppStorage(BudgetSettings.paychequesKey) private var paycheques = BudgetSettings.defaultPaycheques
    @AppStorage(BudgetSettings.returnRateKey) private var returnRate = BudgetSettings.defaultReturnRate
    @AppStorage(BudgetSettings.yearsKey) private var years = BudgetSettings.defaultYears
    @AppStorage(BudgetSettings.usesAgeKey) private var usesAge = false
    @AppStorage(BudgetSettings.startAgeKey) private var startAge = BudgetSettings.defaultStartAge
    @AppStorage(BudgetSettings.showsPayMethodsKey) private var showsPayMethods = true
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var editingItem: BudgetItem?
    @State private var newItemCategory: BudgetCategory?

    private var summary: BudgetSummary { BudgetSummary(items: items) }

    private var points: [RetirementProjection.Point] {
        RetirementProjection.points(annualContribution: summary.annualSavings, rate: returnRate, years: years)
    }

    /// Four columns side by side on iPad, two by two on iPhone.
    private var columnCount: Int { sizeClass == .regular ? 4 : 2 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    grid(BudgetCategory.allCases.map { category in AnyView(column(for: category)) })
                    grid([AnyView(totalsBlock), AnyView(annualBlock)])
                    grid([AnyView(spendBlock), AnyView(retirementBlock)])
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .navigationTitle("Sheet")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $newItemCategory) { category in
                BudgetItemEditorView(item: nil, category: category)
            }
            .sheet(item: $editingItem) { item in
                BudgetItemEditorView(item: item, category: item.category)
            }
        }
    }

    private func grid(_ blocks: [AnyView]) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top), count: min(columnCount, blocks.count))
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            ForEach(blocks.indices, id: \.self) { blocks[$0] }
        }
    }

    // MARK: Budget columns

    private func column(for category: BudgetCategory) -> some View {
        let group = BudgetItem.sorted(items.filter { $0.category == category })
        let showsMethod = showsPayMethods && category.usesPayMethod
        // At least ten rows, like the sheet, and always one empty row to add to.
        let rowCount = max(10, group.count + 1)
        return SheetBlock(color: category.color) {
            SheetHeaderCell(title: category.singularTitle.uppercased(), color: category.color) {
                Button("Add \(category.singularTitle)", systemImage: "plus") { newItemCategory = category }
                    .labelStyle(.iconOnly)
            }
            SheetColumnTitles(showsMethod: showsMethod, color: category.color)
            ForEach(0..<rowCount, id: \.self) { index in
                if index < group.count {
                    let item = group[index]
                    Button { editingItem = item } label: {
                        SheetItemCell(item: item, showsMethod: showsMethod, color: category.color, shaded: index.isMultiple(of: 2))
                    }
                    .buttonStyle(.plain)
                } else {
                    Button { newItemCategory = category } label: {
                        SheetEmptyCell(color: category.color, shaded: index.isMultiple(of: 2))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add \(category.singularTitle)")
                }
            }
            SheetTotalCell(title: "Total", value: summary.total(for: category), color: category.color)
        }
    }

    // MARK: Totals

    private var totalsBlock: some View {
        SheetBlock(color: .income) {
            SheetHeaderCell(title: "MONTHLY", color: .income)
            SheetValueCell(title: "Total Income", value: summary.income, color: .income, shaded: true)
            SheetValueCell(title: "Total Expenses", value: summary.totalExpenses, color: .income, shaded: false)
            SheetTotalCell(title: "Take Home", value: summary.takeHome, color: .income)
        }
    }

    private var annualBlock: some View {
        SheetBlock(color: .annual) {
            SheetHeaderCell(title: "ANNUAL", color: .annual)
            SheetValueCell(title: "Income", value: summary.annualIncome(paychequesPerYear: paycheques), color: .annual, shaded: true)
            SheetValueCell(title: "Expenses", value: summary.annualExpenses, color: .annual, shaded: false)
            SheetValueCell(title: "Take Home", value: summary.annualTakeHome, color: .annual, shaded: true)
            SheetTotalCell(title: "Savings", value: summary.annualSavings, color: .annual)
        }
    }

    // MARK: Charts

    private var spendBlock: some View {
        SheetBlock(color: .secondary) {
            SheetHeaderCell(title: "MONTHLY SPEND", color: .gray)
            let slices = summary.spendSlices
            if slices.isEmpty {
                Text("Add income and expenses to fill the pie.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .padding(8)
            } else {
                VStack(spacing: 8) {
                    Chart(slices) { slice in
                        SectorMark(angle: .value("Amount", slice.amount), innerRadius: .ratio(0.55), angularInset: 1)
                            .cornerRadius(3)
                            .foregroundStyle(slice.kind.color)
                            .accessibilityLabel(slice.kind.rawValue)
                            .accessibilityValue("\(slice.amount.cad), \(slice.share.percent)")
                    }
                    .frame(height: 120)
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(slices) { slice in
                            HStack(spacing: 6) {
                                Circle().fill(slice.kind.color).frame(width: 8, height: 8)
                                Text(slice.kind.rawValue).lineLimit(1)
                                Spacer(minLength: 4)
                                Text(slice.share.percent).monospacedDigit()
                            }
                        }
                    }
                    .font(.caption2)
                    .minimumScaleFactor(0.8)
                }
                .padding(8)
            }
        }
    }

    private var retirementBlock: some View {
        SheetBlock(color: .retirement) {
            SheetHeaderCell(title: "RETIREMENT", color: .retirement)
            VStack(alignment: .leading, spacing: 4) {
                Text((points.last?.balance ?? 0).cadWhole)
                    .font(.headline.bold())
                    .monospacedDigit()
                    .foregroundStyle(Color.retirement)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(usesAge ? "by age \(startAge + years - 1) at \(returnRate.percent)" : "after \(years) years at \(returnRate.percent)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Chart(points) { point in
                    AreaMark(x: .value("Year", point.year), y: .value("Balance", point.balance))
                        .foregroundStyle(Color.retirement.opacity(0.25))
                    LineMark(x: .value("Year", point.year), y: .value("Balance", point.balance))
                        .foregroundStyle(Color.retirement)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 90)
                .accessibilityLabel("Retirement savings by year")
            }
            .padding(8)
        }
    }
}

// MARK: - Cells

/// A bordered block of cells, like a range of the sheet.
private struct SheetBlock<Content: View>: View {
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8).strokeBorder(color.opacity(0.5), lineWidth: 1)
        }
    }
}

/// A solid header band in the block's colour, with an optional button on the right.
private struct SheetHeaderCell<Accessory: View>: View {
    let title: String
    let color: Color
    @ViewBuilder let accessory: Accessory

    init(title: String, color: Color, @ViewBuilder accessory: () -> Accessory = { EmptyView() }) {
        self.title = title
        self.color = color
        self.accessory = accessory()
    }

    var body: some View {
        HStack {
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 4)
            accessory
        }
        .font(.caption.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(color)
        .accessibilityAddTraits(.isHeader)
    }
}

/// The sub-column titles under a column's header.
private struct SheetColumnTitles: View {
    let showsMethod: Bool
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text("NAME")
            Spacer(minLength: 2)
            if showsMethod {
                Text("PAY METHOD")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Text("AMOUNT")
        }
        .font(.system(size: 9, weight: .semibold))
        .foregroundStyle(color)
        .lineLimit(1)
        .padding(.horizontal, 8)
        .frame(height: 20)
        .background(color.opacity(0.2))
        .accessibilityHidden(true)
    }
}

private struct SheetItemCell: View {
    let item: BudgetItem
    let showsMethod: Bool
    let color: Color
    let shaded: Bool

    var body: some View {
        HStack(spacing: 4) {
            if let symbolName = item.symbolName {
                Image(systemName: symbolName)
                    .foregroundStyle(color)
                    .frame(width: 14)
            }
            Text(item.name)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            if showsMethod {
                Text(item.payMethod?.name ?? "")
                    .foregroundStyle(item.payMethod?.color.color ?? .secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Text(item.amount.cad)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize()
        }
        .font(.caption2)
        .padding(.horizontal, 8)
        .frame(height: 22)
        .background(color.opacity(shaded ? 0.12 : 0.05))
        .contentShape(.rect)
        .overlay(alignment: .bottom) { SheetGridLine(color: color) }
        .accessibilityElement(children: .combine)
    }
}

private struct SheetEmptyCell: View {
    let color: Color
    let shaded: Bool

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 22)
            .background(color.opacity(shaded ? 0.12 : 0.05))
            .contentShape(.rect)
            .overlay(alignment: .bottom) { SheetGridLine(color: color) }
    }
}

private struct SheetValueCell: View {
    let title: String
    let value: Double
    let color: Color
    let shaded: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(title).lineLimit(1)
            Spacer(minLength: 4)
            Text(value.cad)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(value < 0 ? Color.overspent : Color.primary)
        }
        .font(.caption2)
        .padding(.horizontal, 8)
        .frame(height: 22)
        .background(color.opacity(shaded ? 0.12 : 0.05))
        .overlay(alignment: .bottom) { SheetGridLine(color: color) }
        .accessibilityElement(children: .combine)
    }
}

/// The bold totals row at the bottom of a block.
private struct SheetTotalCell: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(title).lineLimit(1)
            Spacer(minLength: 4)
            Text(value.cad)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(value < 0 ? Color.overspent : Color.primary)
                .contentTransition(.numericText(value: value))
        }
        .font(.caption.bold())
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(color.opacity(0.3))
        .accessibilityElement(children: .combine)
    }
}

private struct SheetGridLine: View {
    let color: Color

    var body: some View {
        Rectangle()
            .fill(color.opacity(0.25))
            .frame(height: 0.5)
    }
}

#Preview {
    SheetView()
        .modelContainer(PreviewData.container)
}
