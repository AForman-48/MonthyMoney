import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(AppAppearance.storageKey) private var appearance: AppAppearance = .system
    @AppStorage(BudgetSettings.incomeMonthsKey) private var incomeMonths = BudgetSettings.defaultIncomeMonths
    @State private var isConfirmingDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } header: {
                    Text("Appearance")
                }

                Section("Budget") {
                    NavigationLink {
                        PayMethodsView()
                    } label: {
                        Label("Pay Methods", systemImage: "creditcard")
                    }
                }

                Section {
                    Stepper(value: $incomeMonths, in: 12...16, step: 0.5) {
                        LabeledContent("Months of Pay") {
                            Text(incomeMonths.formatted()).monospacedDigit()
                        }
                    }
                } header: {
                    Text("Annual Income")
                } footer: {
                    Text("Annual Income is your monthly income times this number. Your spreadsheet used 14; use 12 for pay that's the same every month.")
                }

                Section {
                    Button(role: .destructive) {
                        isConfirmingDelete = true
                    } label: {
                        Label {
                            Text("Delete Budget")
                        } icon: {
                            Image(systemName: "trash").foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Reset")
                } footer: {
                    Text("Removes every income, expense and savings entry. Pay methods are kept.")
                }
            }
            .confirmationDialog("Delete your budget?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
                Button("Delete Budget", role: .destructive) {
                    DataReset.deleteAll(includingPayMethods: false, in: context)
                    dismiss()
                }
            } message: {
                Text("Every entry is removed. This can't be undone, and with iCloud sync on it also removes them from your other devices.")
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewData.container)
}
