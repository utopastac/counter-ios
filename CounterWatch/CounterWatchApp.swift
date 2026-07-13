import SwiftUI
import SwiftData

@main
struct CounterWatchApp: App {
  @State private var healthKitManager = HealthKitManager()

  var body: some Scene {
    WindowGroup {
      WatchContentView()
        .environment(healthKitManager)
        .task {
          await healthKitManager.requestAuthorization()
        }
        .onChange(of: healthKitManager.activeCalories) { _, burned in
          WidgetSnapshot.publish(added: WidgetSnapshot.added, burned: Int(burned))
        }
    }
    .modelContainer(SharedModelContainer.shared)
  }
}
