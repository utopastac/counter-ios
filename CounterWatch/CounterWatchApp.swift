import SwiftUI
import SwiftData

@main
struct CounterWatchApp: App {
  var body: some Scene {
    WindowGroup {
      WatchContentView()
    }
    .modelContainer(SharedModelContainer.shared)
  }
}
