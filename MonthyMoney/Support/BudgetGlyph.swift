import Foundation

/// SF Symbols offered for budget items, grouped the way bills usually are.
enum BudgetGlyph {
    struct Group: Identifiable {
        let title: String
        let symbols: [String]
        var id: String { title }
    }

    static let groups: [Group] = [
        Group(title: "Income", symbols: [
            "banknote", "dollarsign.circle", "briefcase", "building.2", "gift", "arrow.down.circle",
        ]),
        Group(title: "Home", symbols: [
            "house", "building", "key", "bolt", "drop", "flame", "wifi", "phone", "sofa", "wrench.and.screwdriver",
        ]),
        Group(title: "Getting Around", symbols: [
            "car", "fuelpump", "bus", "tram", "bicycle", "airplane", "parkingsign",
        ]),
        Group(title: "Food", symbols: [
            "cart", "basket", "fork.knife", "cup.and.saucer", "takeoutbag.and.cup.and.straw", "wineglass",
        ]),
        Group(title: "Subscriptions", symbols: [
            "tv", "play.rectangle", "music.note", "gamecontroller", "headphones", "book", "newspaper", "icloud", "sparkles",
        ]),
        Group(title: "Health", symbols: [
            "heart", "cross.case", "pills", "figure.run", "dumbbell", "stethoscope", "scissors",
        ]),
        Group(title: "Money", symbols: [
            "creditcard", "building.columns", "chart.line.uptrend.xyaxis", "banknote.fill", "percent", "shield", "umbrella",
        ]),
        Group(title: "Family and Pets", symbols: [
            "person.2", "figure.and.child.holdinghands", "graduationcap", "pawprint", "teddybear", "tshirt",
        ]),
    ]
}
