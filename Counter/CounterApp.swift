import SwiftUI
import SwiftData

@main
struct CounterApp: App {
  init() {
    if UITesting.isEnabled {
      UITesting.preparePreferences()
    }
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .modelContainer(SharedModelContainer.shared)
  }
}
