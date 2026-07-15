import Foundation
import SwiftData

enum AppDataReset {
  static let suppressSampleSeedingKey = "app.data.suppressSampleSeeding"

  @MainActor
  static func resetAll(in context: ModelContext) {
    deleteAll(CustomCounter.self, in: context)
    deleteAll(CounterEntry.self, in: context)
    deleteAll(CalorieEntry.self, in: context)
    deleteAll(AppSettings.self, in: context)
    AppLog.attempt("Save full data reset") { try context.save() }

    EntryActions.clearAllQuickAddSessions()
    WidgetSnapshot.clear()
    UserDefaults.standard.set(true, forKey: suppressSampleSeedingKey)
  }

  private static func deleteAll<T: PersistentModel>(_ type: T.Type, in context: ModelContext) {
    let items = (try? context.fetch(FetchDescriptor<T>())) ?? []
    for item in items {
      context.delete(item)
    }
  }
}
