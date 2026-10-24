import SwiftData
import SwiftUI

/// Adds a new budget item, or edits an existing one when `item` is set.
struct BudgetItemEditorView: View {
    let item: BudgetItem?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var category: BudgetCategory
    @State private var name = ""
    @State private var amount: Double?
    @State private var payMethod: PayMethod?
    @State private var notes = ""
    @State private var isConfirmingDelete = false
    @FocusState private var nameFocused: Bool

    init(item: BudgetItem?, category: BudgetCategory) {
        self.item = item
        _category = State(initialValue: category)
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .focused($nameFocused)
                        .submitLabel(.done)
                    LabeledContent("Monthly Amount") {
                        TextField("0.00", value: $amount, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                    }
                } footer: {
                    if let amount, amount > 0 {
                        Text("\(amount.cad) a month is \((amount * 12).cad) a year.")
                    }
                }

                Section {
                    Picker("Category", selection: $category) {
                        ForEach(BudgetCategory.allCases) { category in
                            Label(category.title, systemImage: category.systemImage).tag(category)
                        }
                    }
                    if category.usesPayMethod {
                        PayMethodPicker(selection: $payMethod)
                    }
                }

                Section("Notes") {
                    TextField("Due date, account number, reminders", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if item != nil {
                    Section {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            isConfirmingDelete = true
                        }
                    }
                }
            }
            .tint(category.color)
            .navigationTitle(item == nil ? "New \(category.singularTitle)" : "Edit \(category.singularTitle)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark") { save() }
                        .disabled(trimmedName.isEmpty)
                }
            }
            .confirmationDialog("Delete \(trimmedName.isEmpty ? "this item" : trimmedName)?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let item { context.delete(item) }
                    try? context.save()
                    dismiss()
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let item else {
            nameFocused = true
            return
        }
        name = item.name
        amount = item.amount
        payMethod = item.payMethod
        notes = item.notes
    }

    private func save() {
        let target = item ?? {
            let newItem = BudgetItem(
                name: trimmedName,
                amount: 0,
                category: category,
                sortOrder: BudgetItem.nextSortOrder(for: category, in: context)
            )
            context.insert(newItem)
            return newItem
        }()
        if target.category != category {
            target.sortOrder = BudgetItem.nextSortOrder(for: category, in: context)
            target.category = category
        }
        target.name = trimmedName
        target.amount = amount ?? 0
        target.payMethod = category.usesPayMethod ? payMethod : nil
        target.notes = notes
        try? context.save()
        dismiss()
    }
}

#Preview {
    BudgetItemEditorView(item: nil, category: .essential)
        .modelContainer(PreviewData.container)
}
