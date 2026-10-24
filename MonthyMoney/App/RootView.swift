import Combine
import CoreData
import SwiftData
import SwiftUI

enum AppTab: String {
    case budget, summary, retirement
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @SceneStorage("selectedTab") private var selectedTab: AppTab = .budget

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Budget", systemImage: "list.bullet.rectangle.portrait", value: AppTab.budget) {
                BudgetView()
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
        .tabViewBottomAccessory {
            TakeHomeAccessory()
        }
        #if DEBUG
        .onAppear {
            switch ScreenshotMode.screen {
            case "summary": selectedTab = .summary
            case "retirement": selectedTab = .retirement
            case "budget", "settings": selectedTab = .budget
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

/// Monthly take home, always in view above the tab bar.
struct TakeHomeAccessory: View {
    @Query private var items: [BudgetItem]
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    var body: some View {
        let summary = BudgetSummary(items: items)
        HStack(spacing: 10) {
            Image(systemName: summary.takeHome >= 0 ? "arrow.down.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(summary.takeHome >= 0 ? Color.income : Color.retirement)
            if placement != .inline {
                Text("Take Home")
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            Text(summary.takeHome.cad)
                .fontWeight(.semibold)
                .monospacedDigit()
                .contentTransition(.numericText(value: summary.takeHome))
            if placement != .inline {
                Text("/ mo")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .animation(.default, value: summary.takeHome)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Take home \(summary.takeHome.cad) a month")
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
