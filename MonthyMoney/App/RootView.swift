import Combine
import CoreData
import SwiftData
import SwiftUI

enum AppTab: String {
    case budget, sheet, summary, retirement
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @SceneStorage("selectedTab") private var selectedTab: AppTab = .budget
    @AppStorage(BudgetSettings.hasCompletedWalkthroughKey) private var hasCompletedWalkthrough = false
    @Query private var items: [BudgetItem]
    @State private var isShowingWalkthrough = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Budget", systemImage: "list.bullet.rectangle.portrait", value: AppTab.budget) {
                BudgetView()
            }
            Tab("Sheet", systemImage: "tablecells", value: AppTab.sheet) {
                SheetView()
            }
            Tab("Summary", systemImage: "chart.pie", value: AppTab.summary) {
                SummaryView()
            }
            Tab("Retirement", systemImage: "chart.line.uptrend.xyaxis", value: AppTab.retirement) {
                RetirementView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
        .onAppear {
            // A budget that already synced from another device needs no walkthrough.
            if !items.isEmpty { hasCompletedWalkthrough = true }
            isShowingWalkthrough = !hasCompletedWalkthrough
        }
        .fullScreenCover(isPresented: $isShowingWalkthrough) {
            WalkthroughView()
        }
        #if DEBUG
        .onAppear {
            switch ScreenshotMode.screen {
            case "sheet": selectedTab = .sheet
            case "summary": selectedTab = .summary
            case "retirement": selectedTab = .retirement
            case "budget", "settings": selectedTab = .budget
            case "walkthrough": isShowingWalkthrough = true
            default: break
            }
        }
        #endif
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { SyncCleanup.mergeDuplicates(in: context) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange).receive(on: RunLoop.main)) { _ in
            SyncCleanup.mergeDuplicates(in: context)
        }
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
