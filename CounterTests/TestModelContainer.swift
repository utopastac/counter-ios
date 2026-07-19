import Foundation
import SwiftData

/// Builds an isolated, in-memory `ModelContainer` for tests so they never touch the
/// shared App Group store used by the real app, widgets, or watch target.
@MainActor
enum TestModelContainer {
  static func make() -> ModelContainer {
    let schema = Schema([
      CustomCounter.self,
      CounterEntry.self
    ])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    do {
      return try ModelContainer(for: schema, configurations: [configuration])
    } catch {
      fatalError("Failed to create in-memory test ModelContainer: \(error)")
    }
  }
}
