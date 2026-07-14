import SwiftUI
import SwiftData

@main
struct CounterApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
        .homeIndicatorAlwaysVisible()
    }
    .modelContainer(SharedModelContainer.shared)
  }
}
