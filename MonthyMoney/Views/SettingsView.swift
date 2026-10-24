import CloudKit
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
                    Toggle(isOn: Bindable(DisplaySettings.shared).showsDecimals) {
                        Label("Show Cents", systemImage: "centsign")
                    }
                } header: {
                    Text("Amounts")
                } footer: {
                    Text("Turn off to show amounts rounded to the nearest dollar. Your exact amounts are kept, and totals still add up the cents.")
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
                    ICloudStatusRow()
                } header: {
                    Text("iCloud")
                } footer: {
                    Text("Your budget, pay methods and settings sync to your other iPhone and iPad signed in to the same Apple Account. Appearance is set on each device.")
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

/// Whether iCloud sync is working, from the iCloud account on this device.
private struct ICloudStatusRow: View {
    @State private var status: String?

    var body: some View {
        LabeledContent {
            Text(status ?? "Checking…")
        } label: {
            Label("iCloud Sync", systemImage: "icloud")
        }
        .task { status = await Self.currentStatus() }
    }

    private static func currentStatus() async -> String {
        guard CloudSync.isEnabled else { return "Off in This Build" }
        let accountStatus = try? await CKContainer(identifier: CloudSync.containerIdentifier).accountStatus()
        switch accountStatus {
        case .available: return "On"
        case .noAccount: return "Sign In to iCloud"
        case .restricted: return "Restricted"
        case .temporarilyUnavailable: return "Temporarily Unavailable"
        default: return "Unavailable"
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewData.container)
}
