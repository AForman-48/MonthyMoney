import SwiftData
import SwiftUI

/// The accounts and cards offered in the Pay Method picker.
struct PayMethodsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\PayMethod.sortOrder), SortDescriptor(\PayMethod.name)]) private var methods: [PayMethod]
    @State private var editingMethod: PayMethod?
    @State private var isAdding = false

    var body: some View {
        List {
            Section {
                ForEach(methods) { method in
                    Button {
                        editingMethod = method
                    } label: {
                        HStack {
                            PayMethodBadge(method: method)
                            Spacer()
                            let count = method.items?.count ?? 0
                            Text(count == 1 ? "1 item" : "\(count) items")
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
                .onMove(perform: move)
                .onDelete(perform: delete)
            } footer: {
                Text("Deleting a pay method leaves its items with no pay method.")
            }
        }
        .navigationTitle("Pay Methods")
        .overlay {
            if methods.isEmpty {
                ContentUnavailableView {
                    Label("No Pay Methods", systemImage: "creditcard")
                } description: {
                    Text("Add the accounts and cards your bills come out of.")
                } actions: {
                    Button("Add Pay Method") { isAdding = true }
                        .buttonStyle(.glassProminent)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add Pay Method", systemImage: "plus") { isAdding = true }
            }
        }
        .sheet(isPresented: $isAdding) {
            PayMethodEditorView(method: nil)
        }
        .sheet(item: $editingMethod) { method in
            PayMethodEditorView(method: method)
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = methods
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, method) in reordered.enumerated() where method.sortOrder != index {
            method.sortOrder = index
        }
        try? context.save()
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { context.delete(methods[index]) }
        try? context.save()
    }
}

/// Adds a pay method, or edits one when `method` is set.
struct PayMethodEditorView: View {
    let method: PayMethod?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name = ""
    @State private var color: PayMethodColor = .blue
    @FocusState private var nameFocused: Bool

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name, like TD Visa", text: $name)
                        .focused($nameFocused)
                        .submitLabel(.done)
                }

                Section("Colour") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 12)], spacing: 12) {
                        ForEach(PayMethodColor.allCases) { option in
                            Button {
                                color = option
                            } label: {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if option == color {
                                            Image(systemName: "checkmark")
                                                .font(.subheadline.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .padding(4)
                                    .overlay {
                                        Circle().strokeBorder(option == color ? option.color : .clear, lineWidth: 2)
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(option.title)
                            .accessibilityAddTraits(option == color ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Preview") {
                    PayMethodBadge(name: trimmedName.isEmpty ? "Pay Method" : trimmedName, color: color.color)
                }
            }
            .navigationTitle(method == nil ? "New Pay Method" : "Edit Pay Method")
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
            .onAppear {
                if let method {
                    name = method.name
                    color = method.color
                } else {
                    nameFocused = true
                }
            }
        }
    }

    private func save() {
        let target = method ?? {
            let newMethod = PayMethod(name: trimmedName, color: color, sortOrder: PayMethod.nextSortOrder(in: context))
            context.insert(newMethod)
            return newMethod
        }()
        target.name = trimmedName
        target.color = color
        try? context.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        PayMethodsView()
    }
    .modelContainer(PreviewData.container)
}
