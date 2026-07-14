import Foundation
import SwiftData

enum WidgetSnapshotSync {
  static func publish(from context: ModelContext, burned: Int) {
    let settings = fetchSettings(in: context)
    let entries = fetchCalorieEntries(in: context)
    let added = CounterPeriodCalculator.totalCalories(from: entries, for: settings)

    WidgetSnapshot.publish(added: added, burned: burned)
  }

  private static func fetchSettings(in context: ModelContext) -> AppSettings {
    var descriptor = FetchDescriptor<AppSettings>()
    descriptor.fetchLimit = 1
    return (try? context.fetch(descriptor).first) ?? AppSettings()
  }

  private static func fetchCalorieEntries(in context: ModelContext) -> [CalorieEntry] {
    (try? context.fetch(FetchDescriptor<CalorieEntry>())) ?? []
  }
}
