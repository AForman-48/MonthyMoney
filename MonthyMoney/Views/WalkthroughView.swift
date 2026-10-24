import SwiftData
import SwiftUI

/// First-run setup: monthly income, one essential and one non-essential expense.
struct WalkthroughView: View {
    enum Step: Int, CaseIterable {
        case welcome, income, essential, nonEssential, done
    }

    /// One entry being filled in during the walkthrough.
    struct Entry {
        var name: String
        var amount: Double?
        var payMethod: PayMethod?
        let symbolName: String

        var isComplete: Bool {
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (amount ?? 0) > 0
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(BudgetSettings.hasCompletedWalkthroughKey) private var hasCompletedWalkthrough = false
    @State private var step: Step = .welcome
    @State private var income = Entry(name: "Paycheque", symbolName: "banknote")
    @State private var essential = Entry(name: "", symbolName: "house")
    @State private var nonEssential = Entry(name: "", symbolName: "tv")
    @FocusState private var amountFocused: Bool

    private var summary: BudgetSummary {
        BudgetSummary(income: income.amount ?? 0, essentials: essential.amount ?? 0, nonEssentials: nonEssential.amount ?? 0)
    }

    private var canContinue: Bool {
        switch step {
        case .welcome, .done: true
        case .income: income.isComplete
        case .essential: essential.isComplete
        case .nonEssential: nonEssential.isComplete
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                switch step {
                case .welcome: welcome
                case .income:
                    entrySection(
                        $income,
                        category: .income,
                        title: "What do you bring home each month?",
                        message: "Enter your monthly income after tax. Every amount in MonthyMoney is monthly.",
                        namePrompt: "Paycheque"
                    )
                case .essential:
                    entrySection(
                        $essential,
                        category: .essential,
                        title: "Add an essential",
                        message: "Something you have to pay every month, like rent or a mortgage.",
                        namePrompt: "Rent or mortgage"
                    )
                case .nonEssential:
                    entrySection(
                        $nonEssential,
                        category: .nonEssential,
                        title: "Add a non-essential",
                        message: "Something you choose to pay for, like a streaming subscription.",
                        namePrompt: "Streaming subscription"
                    )
                case .done: done
                }
            }
            .animation(.default, value: step)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if step != .welcome && step != .done {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back", systemImage: "chevron.backward") { move(by: -1) }
                    }
                }
                ToolbarItem(placement: .principal) {
                    StepDots(current: step.rawValue, count: Step.allCases.count)
                }
            }
            .safeAreaBar(edge: .bottom) {
                Button {
                    if step == .done { finish() } else { move(by: 1) }
                } label: {
                    Text(buttonTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .disabled(!canContinue)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .interactiveDismissDisabled()
    }

    private var buttonTitle: String {
        switch step {
        case .welcome: "Get Started"
        case .done: "Open My Budget"
        default: "Continue"
        }
    }

    private var welcome: some View {
        Section {
            VStack(spacing: 16) {
                HStack(spacing: 10) {
                    ForEach(BudgetCategory.allCases) { category in
                        GlyphTile(symbolName: category.systemImage, color: category.color, size: 52)
                    }
                }
                Text("Welcome to MonthyMoney")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text("Track what comes in and goes out each month, see what you take home, and watch your savings grow. Let's start with three things: your income, one essential and one non-essential.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .listRowBackground(Color.clear)
        }
    }

    private var done: some View {
        Group {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.income)
                    Text("You're all set")
                        .font(.largeTitle.bold())
                    Text("Add the rest of your bills and savings on the Budget tab whenever you're ready.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .listRowBackground(Color.clear)
            }
            Section("So Far") {
                SummaryRow(title: "Income", value: summary.income, systemImage: "banknote", color: .income)
                SummaryRow(title: "Expenses", value: summary.totalExpenses, systemImage: "cart", color: .essentials)
                SummaryRow(title: "Take Home", value: summary.takeHome, systemImage: "arrow.down.circle", color: .income)
            }
        }
    }

    private func entrySection(
        _ entry: Binding<Entry>,
        category: BudgetCategory,
        title: String,
        message: String,
        namePrompt: String
    ) -> some View {
        Group {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    GlyphTile(symbolName: entry.wrappedValue.symbolName, color: category.color, size: 56)
                    Text(title)
                        .font(.title.bold())
                    Text(message)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }
            Section {
                TextField(namePrompt, text: entry.name)
                    .submitLabel(.next)
                    .onSubmit { amountFocused = true }
                LabeledContent("Monthly Amount") {
                    TextField("0.00", value: entry.amount, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .monospacedDigit()
                        .focused($amountFocused)
                }
                if category.usesPayMethod {
                    PayMethodPicker(selection: entry.payMethod)
                }
            } footer: {
                if category.usesPayMethod {
                    Text("Pick the account or card it comes out of, or leave it for later.")
                }
            }
            .listRowBackground(category.color.opacity(0.14))
        }
        .tint(category.color)
    }

    private func move(by offset: Int) {
        guard let next = Step(rawValue: step.rawValue + offset) else { return }
        amountFocused = false
        step = next
    }

    private func finish() {
        let entries: [(Entry, BudgetCategory)] = [(income, .income), (essential, .essential), (nonEssential, .nonEssential)]
        for (entry, category) in entries where entry.isComplete {
            let item = BudgetItem(
                name: entry.name.trimmingCharacters(in: .whitespacesAndNewlines),
                amount: entry.amount ?? 0,
                category: category,
                payMethod: category.usesPayMethod ? entry.payMethod : nil,
                sortOrder: BudgetItem.nextSortOrder(for: category, in: context)
            )
            item.symbolName = entry.symbolName
            context.insert(item)
        }
        try? context.save()
        hasCompletedWalkthrough = true
        dismiss()
    }
}

/// Small dots showing how far through the walkthrough you are.
private struct StepDots: View {
    let current: Int
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.primary : Color.secondary.opacity(0.35))
                    .frame(width: index == current ? 18 : 7, height: 7)
            }
        }
        .animation(.snappy, value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current + 1) of \(count)")
    }
}

#Preview {
    WalkthroughView()
        .modelContainer(PreviewData.container)
}
