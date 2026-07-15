import Foundation
import SwiftData

/// `nonisolated` so `migrateIfNeeded` can run synchronously from `CounterMigrationPlan`'s
/// `willMigrate` closure, which SwiftData invokes off the main actor as a `@Sendable`
/// closure. `ModelContext` itself isn't `Sendable`, but SwiftData hands this specific
/// context to the closure precisely so it can be mutated synchronously during migration —
/// there's no cross-actor hop here, just a context that was never main-actor-bound to begin
/// with (unlike `SharedModelContainer`'s context, which is only ever touched from the main actor).
nonisolated enum CalorieMigration {
  static func migrateIfNeeded(in context: ModelContext) {
    let calorieEntries = fetchCalorieEntries(in: context)
    let settings = fetchAppSettings(in: context)

    guard !calorieEntries.isEmpty || settings != nil else { return }

    let counter = findCaloriesCounter(in: context) ?? createCaloriesCounter(from: settings, in: context)

    for entry in calorieEntries {
      let counterEntry = CounterEntry(
        value: entry.value,
        timestamp: entry.timestamp,
        counter: counter
      )
      context.insert(counterEntry)
      context.delete(entry)
    }

    if let settings {
      applySettings(settings, to: counter)
      context.delete(settings)
    }

    AppLog.attempt("Save calorie migration") { try context.save() }
  }

  private static func findCaloriesCounter(in context: ModelContext) -> CustomCounter? {
    var descriptor = FetchDescriptor<CustomCounter>(
      predicate: #Predicate { $0.name == "Calories" },
      sortBy: [SortDescriptor(\.createdAt)]
    )
    descriptor.fetchLimit = 1
    return try? context.fetch(descriptor).first
  }

  private static func createCaloriesCounter(
    from settings: AppSettings?,
    in context: ModelContext
  ) -> CustomCounter {
    let counter = CustomCounter(
      name: "Calories",
      buttonValues: settings?.calorieButtonValues ?? QuickAddConfiguration.defaultCaloriePresets,
      sliderMax: settings?.effectiveCalorieSliderMax ?? 2000,
      goal: settings?.effectiveCalorieGoal ?? CustomCounter.defaultCalorieGoal,
      resetPeriod: settings?.calorieResetPeriod ?? .daily,
      resetAnchorDay: settings?.effectiveCalorieResetAnchorDay ?? 1,
      goalDirection: settings?.calorieGoalDirection ?? .countDown
    )
    counter.createdAt = .distantPast
    context.insert(counter)
    return counter
  }

  private static func applySettings(_ settings: AppSettings, to counter: CustomCounter) {
    counter.buttonValues = settings.calorieButtonValues
    counter.sliderMax = settings.effectiveCalorieSliderMax
    counter.goal = settings.effectiveCalorieGoal
    counter.resetPeriod = settings.calorieResetPeriod
    counter.resetAnchorDay = settings.effectiveCalorieResetAnchorDay
    counter.goalDirection = settings.calorieGoalDirection
  }

  private static func fetchCalorieEntries(in context: ModelContext) -> [CalorieEntry] {
    (try? context.fetch(FetchDescriptor<CalorieEntry>())) ?? []
  }

  private static func fetchAppSettings(in context: ModelContext) -> AppSettings? {
    var descriptor = FetchDescriptor<AppSettings>()
    descriptor.fetchLimit = 1
    return try? context.fetch(descriptor).first
  }
}
