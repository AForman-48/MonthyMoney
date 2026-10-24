import SwiftUI

/// Picks an SF Symbol for a budget item. The glyph takes the category's colour.
struct GlyphPickerView: View {
    let selected: String?
    let color: Color
    let onPick: (String?) -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 52), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if selected != nil {
                        Button("Remove Glyph", systemImage: "trash", role: .destructive) {
                            onPick(nil)
                            dismiss()
                        }
                        .buttonStyle(.glass)
                    }
                    ForEach(BudgetGlyph.groups) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(group.title)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(group.symbols, id: \.self) { symbol in
                                    Button {
                                        onPick(symbol)
                                        dismiss()
                                    } label: {
                                        GlyphTile(symbolName: symbol, color: color, size: 52)
                                            .overlay {
                                                if symbol == selected {
                                                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                                                        .strokeBorder(.primary, lineWidth: 3)
                                                }
                                            }
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(symbol.replacingOccurrences(of: ".", with: " "))
                                    .accessibilityAddTraits(symbol == selected ? .isSelected : [])
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Glyph")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                }
            }
        }
    }
}

/// A glyph on a rounded square in the category's colour.
struct GlyphTile: View {
    let symbolName: String
    let color: Color
    var size: CGFloat = 34

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: size * 0.46, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color.gradient, in: .rect(cornerRadius: size * 0.28, style: .continuous))
            .accessibilityHidden(true)
    }
}

#Preview {
    GlyphPickerView(selected: "house", color: .essentials) { _ in }
}
