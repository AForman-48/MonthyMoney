import SwiftData
import SwiftUI

struct BudgetView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @Query private var items: [BudgetItem]
    @Query(sort: [SortDescriptor(\PayMethod.sortOrder), SortDescriptor(\PayMethod.name)]) private var payMethods: [PayMethod]
    @AppStorage(BudgetSettings.showsPayMethodsKey) private var showsPayMethods = BudgetSettings.defaultShowsPayMethods
    @State private var searchText = ""
    @State private var newItemCategory: BudgetCategory?
    @State private var editingItem: BudgetItem?
    @State private var isShowingSettings = false
    @State private var isShowingPayMethods = false

    private var filteredItems: [BudgetItem] {
        guard !searchText.isEmpty else { return items }
        return items.filter {
            $0.name.localizedStandardContains(searchText)
                || ($0.payMethod?.name.localizedStandardContains(searchText) ?? false)
        }
    }

    private var summary: BudgetSummary { BudgetSummary(items: items) }

    /// The tint behind rows, like the shaded cells of the sheet.
    private func rowTint(_ category: BudgetCategory) -> Color {
        category.color.opacity(colorScheme == .dark ? 0.24 : 0.14)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(BudgetCategory.allCases) { category in
                    let group = BudgetItem.sorted(filteredItems.filter { $0.category == category })
                    if !group.isEmpty || searchText.isEmpty {
                        Section {
                            CategoryHeader(category: category, total: summary.total(for: category))
                                .listRowBackground(category.color)
                            ForEach(group) { row(for: $0) }
                                .onMove { move(group, from: $0, to: $1) }
                            if searchText.isEmpty {
                                Button {
                                    newItemCategory = category
                                } label: {
                                    Label("Add \(category.singularTitle)", systemImage: "plus.circle.fill")
                                        .foregroundStyle(category.color)
                                }
                                .listRowBackground(rowTint(category))
                            }
                        }
                    }
                }
            }
            .listSectionSpacing(20)
            .animation(.default, value: items.map(\.amount))
            .navigationTitle("Budget")
            .searchable(text: $searchText, prompt: "Search budget")
            .overlay {
                if !searchText.isEmpty && filteredItems.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .safeAreaBar(edge: .bottom) {
                TakeHomeBar(takeHome: summary.takeHome)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Settings", systemImage: "gearshape") { isShowingSettings = true }
                }
                if showsPayMethods {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Pay Methods", systemImage: "creditcard") { isShowingPayMethods = true }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("Add", systemImage: "plus") {
                        ForEach(BudgetCategory.allCases) { category in
                            Button(category.singularTitle, systemImage: category.systemImage) {
                                newItemCategory = category
                            }
                        }
                    }
                }
            }
            #if DEBUG
            .onAppear {
                if ScreenshotMode.screen == "settings" { isShowingSettings = true }
            }
            #endif
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $isShowingPayMethods) {
                PayMethodsSheet()
            }
            .sheet(item: $newItemCategory) { category in
                BudgetItemEditorView(item: nil, category: category)
            }
            .sheet(item: $editingItem) { item in
                BudgetItemEditorView(item: item, category: item.category)
            }
        }
    }

    private func row(for item: BudgetItem) -> some View {
        Button {
            editingItem = item
        } label: {
            BudgetItemRow(item: item, showsPayMethod: showsPayMethods)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .listRowBackground(rowTint(item.category))
        .swipeActions(edge: .trailing) {
            Button("Delete", systemImage: "trash", role: .destructive) { delete(item) }
        }
        .contextMenu {
            Button("Edit", systemImage: "pencil") { editingItem = item }
            if showsPayMethods && item.category.usesPayMethod {
                Picker("Pay Method", systemImage: "creditcard", selection: Binding(
                    get: { item.payMethod },
                    set: { item.payMethod = $0; try? context.save() }
                )) {
                    Text("None").tag(PayMethod?.none)
                    ForEach(payMethods) { Text($0.name).tag(PayMethod?.some($0)) }
                }
                .pickerStyle(.menu)
            }
            Button("Duplicate", systemImage: "plus.square.on.square") { duplicate(item) }
            Divider()
            Button("Delete", systemImage: "trash", role: .destructive) { delete(item) }
        }
    }

    private func move(_ group: [BudgetItem], from source: IndexSet, to destination: Int) {
        var reordered = group
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, item) in reordered.enumerated() where item.sortOrder != index {
            item.sortOrder = index
        }
        try? context.save()
    }

    private func duplicate(_ item: BudgetItem) {
        let copy = BudgetItem(
            name: item.name,
            amount: item.amount,
            category: item.category,
            payMethod: item.payMethod,
            sortOrder: BudgetItem.nextSortOrder(for: item.category, in: context)
        )
        copy.notes = item.notes
        copy.symbolName = item.symbolName
        withAnimation {
            context.insert(copy)
            try? context.save()
        }
    }

    private func delete(_ item: BudgetItem) {
        withAnimation {
            context.delete(item)
            try? context.save()
        }
    }
}

/// The coloured title row of a section, like the header cells of the sheet, with its monthly total.
struct CategoryHeader: View {
    let category: BudgetCategory
    let total: Double

    var body: some View {
        HStack {
            Label(category.title.uppercased(), systemImage: category.systemImage)
            Spacer()
            Text(total.cad)
                .monospacedDigit()
                .contentTransition(.numericText(value: total))
        }
        .font(.headline)
        .foregroundStyle(.white)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Monthly take home on a glass bar above the tab bar.
struct TakeHomeBar: View {
    let takeHome: Double

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: takeHome >= 0 ? "arrow.down.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(takeHome >= 0 ? Color.income : Color.overspent)
            Text("Take Home")
                .foregroundStyle(.secondary)
            Spacer(minLength: 4)
            Text(takeHome.cad)
                .fontWeight(.semibold)
                .monospacedDigit()
                .contentTransition(.numericText(value: takeHome))
            Text("/ mo")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .animation(.default, value: takeHome)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Take home \(takeHome.cad) a month")
    }
}

#Preview {
    BudgetView()
        .modelContainer(PreviewData.container)
}
