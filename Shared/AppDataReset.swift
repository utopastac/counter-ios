import Foundation
import SwiftData

enum AppDataReset {
  static let suppressSampleSeedingKey = "app.data.suppressSampleSeeding"

  /// Wipes all counters/entries and restores the default sample counters (Calories, Protein, Money).
  @MainActor
  static func resetAll(in context: ModelContext) {
    // Cascade delete clears entries — do not fetch/delete `CounterEntry` afterward
    // (those objects are already invalidated and will crash).
    for counter in (try? context.fetch(FetchDescriptor<CustomCounter>())) ?? [] {
      context.delete(counter)
    }
    AppLog.attempt("Save full data reset") { try context.save() }

    QuickAddSessionStore.shared.reset()
    WidgetSnapshot.clear()
    UserDefaults.standard.set(false, forKey: suppressSampleSeedingKey)

    SampleDataSeeder.seedDefaults(in: context)

    // Peer wipes first, then receives the restored defaults.
    WatchSyncEngine.publishResetAll()
    WatchSyncEngine.publishFullSnapshot(in: context)
  }
}
