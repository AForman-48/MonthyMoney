import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(AppAppearance.storageKey) private var appearance: AppAppearance = .system
    @AppStorage(BudgetSettings.paychequesKey) private var paycheques = BudgetSettings.defaultPaycheques
    @AppStorage(BudgetSettings.showsPayMethodsKey) private var showsPayMethods = BudgetSettings.defaultShowsPayMethods
    @State private var isConfirmingDelete = false

    /// Monthly income counts as two paycheques, so this says how many months of pay a year holds.
    private var paychequeFooter: String {
        let months = (Double(paycheques) / 2).formatted()
        return "Your monthly income counts as two paycheques. Paid every two weeks, you get 26 a year, with three in two of the months. With \(paycheques) paycheques, Annual Income is \(months) months of pay."
    }

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

                Section {
                    Toggle(isOn: $showsPayMethods.animation()) {
                        Label("Pay Methods", systemImage: "creditcard")
                    }
                    if showsPayMethods {
                        NavigationLink {
                            PayMethodsView()
                        } label: {
                            Label("Manage Pay Methods", systemImage: "slider.horizontal.3")
                        }
                    }
                } header: {
                    Text("Budget")
                } footer: {
                    Text("Track the account or card each expense comes out of. Add your own accounts and cards under Manage Pay Methods.")
                }

                Section {
                    Stepper(value: $paycheques, in: 20...30) {
                        LabeledContent("Paycheques Each Year") {
                            Text("\(paycheques)").monospacedDigit()
                        }
                    }
                } header: {
                    Text("Annual Income")
                } footer: {
                    Text(paychequeFooter)
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
