import SwiftUI
import SwiftData

@main
struct CounterApp: App {
  @State private var healthKitManager = HealthKitManager()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(healthKitManager)
        .task {
          await healthKitManager.requestAuthorization()
        }
    }
    .modelContainer(SharedModelContainer.shared)
  }
}
