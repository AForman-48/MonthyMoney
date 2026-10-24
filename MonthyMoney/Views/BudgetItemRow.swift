import SwiftUI

struct BudgetItemRow: View {
    let item: BudgetItem

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                if let method = item.payMethod, item.category.usesPayMethod {
                    PayMethodBadge(method: method)
                }
            }
            Spacer(minLength: 8)
            Text(item.amount.cad)
                .monospacedDigit()
                .foregroundStyle(item.amount == 0 ? Color.secondary : Color.primary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        BudgetItemRow(item: PreviewData.sampleItem)
    }
    .modelContainer(PreviewData.container)
}
