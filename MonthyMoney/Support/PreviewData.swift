import SwiftData

/// An in-memory store filled with the sample budget, for SwiftUI previews.
enum PreviewData {
    static let container: ModelContainer = {
        let schema = Schema([BudgetItem.self, PayMethod.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try! ModelContainer(for: schema, configurations: configuration)
        SeedData.insertSample(into: container.mainContext)
        return container
    }()

    static var sampleItem: BudgetItem {
        let items = (try? container.mainContext.fetch(FetchDescriptor<BudgetItem>())) ?? []
        return items.first { $0.name == "Rent" } ?? items[0]
    }
}
