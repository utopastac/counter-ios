import Foundation
import SwiftData

/// `nonisolated` so `migrateIfNeeded` can run synchronously from `CounterMigrationPlan`'s
/// `willMigrate` closure. Legacy calorie values are written as hundredths immediately, and
/// `SampleDataSeeder`'s hundredths flag is set so they aren't scaled a second time.
nonisolated enum CalorieMigration {
  static func migrateIfNeeded(in context: ModelContext) {
    let calorieEntries = fetchCalorieEntries(in: context)
    let settings = fetchAppSettings(in: context)

    guard !calorieEntries.isEmpty || settings != nil else { return }

    let counter = findCaloriesCounter(in: context) ?? createCaloriesCounter(from: settings, in: context)

    for entry in calorieEntries {
      let counterEntry = CounterEntry(
        value: Double(entry.value),
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
    UserDefaults.standard.set(true, forKey: "counterAmountsAreHundredths")
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
    let presets: [Double]
    if let values = settings?.calorieButtonValues, !values.isEmpty {
      presets = values.map(Double.init)
    } else {
      presets = QuickAddConfiguration.defaultCaloriePresets
    }

    let counter = CustomCounter(
      name: "Calories",
      unit: CounterTemplate.calories.defaultUnit,
      buttonValues: presets,
      sliderMax: Double(settings?.effectiveCalorieSliderMax ?? 2000),
      goal: settings?.effectiveCalorieGoal.map(Double.init) ?? CustomCounter.defaultCalorieGoal,
      resetPeriod: settings?.calorieResetPeriod ?? .daily,
      resetAnchorDay: settings?.effectiveCalorieResetAnchorDay ?? 1,
      goalDirection: settings?.calorieGoalDirection ?? .countDown,
      sortOrder: 0
    )
    counter.createdAt = .distantPast
    context.insert(counter)
    return counter
  }

  private static func applySettings(_ settings: AppSettings, to counter: CustomCounter) {
    counter.unit = CounterTemplate.calories.defaultUnit
    counter.presetAmounts = settings.calorieButtonValues.map(Double.init)
    counter.sliderMax = CounterAmount.storage(Double(settings.effectiveCalorieSliderMax))
    counter.goal = settings.effectiveCalorieGoal.map { CounterAmount.storage(Double($0)) }
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
