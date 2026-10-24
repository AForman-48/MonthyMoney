import SwiftData
import SwiftUI

struct PayMethodBadge: View {
    let name: String
    let color: Color

    init(method: PayMethod) {
        name = method.name
        color = method.color.color
    }

    init(name: String, color: Color) {
        self.name = name
        self.color = color
    }

    var body: some View {
        // An HStack rather than a Label, which takes on the list's icon column inside rows.
        HStack(spacing: 4) {
            Image(systemName: "creditcard")
            Text(name)
                .lineLimit(1)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15), in: .capsule)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Paid with \(name)")
    }
}

/// A picker for the pay method, with None for an item that has none.
struct PayMethodPicker: View {
    @Binding var selection: PayMethod?
    @Query(sort: [SortDescriptor(\PayMethod.sortOrder), SortDescriptor(\PayMethod.name)]) private var methods: [PayMethod]

    var body: some View {
        Picker("Pay Method", selection: $selection) {
            Text("None").tag(PayMethod?.none)
            ForEach(methods) { method in
                Label {
                    Text(method.name)
                } icon: {
                    Image(systemName: "circle.fill").foregroundStyle(method.color.color)
                }
                .tag(PayMethod?.some(method))
            }
        }
    }
}

#Preview {
    VStack {
        ForEach(PayMethodColor.allCases) { PayMethodBadge(name: $0.title, color: $0.color) }
    }
}
