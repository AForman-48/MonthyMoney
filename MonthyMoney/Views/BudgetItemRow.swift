import SwiftUI

struct BudgetItemRow: View {
    let item: BudgetItem
    var showsPayMethod = true

    var body: some View {
        HStack(spacing: 12) {
            if let symbolName = item.symbolName {
                GlyphTile(symbolName: symbolName, color: item.category.color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                if showsPayMethod, let method = item.payMethod, item.category.usesPayMethod {
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
