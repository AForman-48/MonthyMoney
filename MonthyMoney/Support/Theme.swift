import SwiftUI

// The colours of the budget spreadsheet.
extension Color {
    static let income = Color(red: 0.42, green: 0.66, blue: 0.31)
    static let essentials = Color(red: 0.90, green: 0.45, blue: 0.23)
    static let nonEssentials = Color(red: 0.36, green: 0.56, blue: 0.90)
    static let savings = Color(red: 0.56, green: 0.47, blue: 0.78)
    static let retirement = Color(red: 0.84, green: 0.28, blue: 0.28)
    /// Annual figures sit in the sheet's purple block.
    static let annual = savings
}

/// Colours a pay method can show as.
enum PayMethodColor: String, CaseIterable, Identifiable {
    case navy, blue, teal, forest, green, orange, red, pink, purple, brown, gray

    var id: Self { self }

    var title: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .navy: Color(red: 0.12, green: 0.31, blue: 0.62)
        case .blue: .blue
        case .teal: .teal
        case .forest: Color(red: 0.13, green: 0.47, blue: 0.29)
        case .green: Color(red: 0.42, green: 0.70, blue: 0.25)
        case .orange: .orange
        case .red: .red
        case .pink: .pink
        case .purple: .purple
        case .brown: .brown
        case .gray: .gray
        }
    }
}
