import Foundation
import SwiftData

/// Seeds the default counters when none exist.
enum SampleDataSeeder {
  /// Quick-add presets shown in the design mockups.
  static let mockQuickAddPresets: [Double] = QuickAddConfiguration.defaultCaloriePresets

  @MainActor
  static func seedIfNeeded(in context: ModelContext) {
    guard !UserDefaults.standard.bool(forKey: AppDataReset.suppressSampleSeedingKey) else { return }
    guard !hasAnyCounters(in: context) else { return }

    seedDefaults(in: context)
    WatchSyncEngine.publishFullSnapshot(in: context)
  }

  /// Inserts the three default counters (Calories, Protein, Money) with zero totals.
  /// Caller is responsible for ensuring the store is empty (or accepting duplicates).
  @MainActor
  static func seedDefaults(in context: ModelContext) {
    seedCaloriesCounter(in: context)
    seedProteinCounter(in: context)
    seedMoneyCounter(in: context)

    AppLog.attempt("Save seeded sample data") { try context.save() }
  }

  private static func hasAnyCounters(in context: ModelContext) -> Bool {
    var descriptor = FetchDescriptor<CustomCounter>()
    descriptor.fetchLimit = 1
    return (try? context.fetch(descriptor).isEmpty == false) ?? false
  }

  private static func seedCaloriesCounter(in context: ModelContext) {
    let counter = CustomCounter(
      name: "Calories",
      unit: CounterTemplate.calories.defaultUnit,
      buttonValues: mockQuickAddPresets,
      sliderMax: 2000,
      goal: CustomCounter.defaultCalorieGoal,
      goalDirection: .countDown,
      sortOrder: 0
    )
    counter.createdAt = .distantPast
    counter.paletteIndex = 0
    context.insert(counter)
  }

  private static func seedProteinCounter(in context: ModelContext) {
    let counter = CustomCounter(
      name: "Protein",
      unit: CounterTemplate.protein.defaultUnit,
      buttonValues: CounterTemplate.protein.defaultPresets,
      goal: 150,
      goalDirection: .countUp,
      sortOrder: 1
    )
    counter.createdAt = .now.addingTimeInterval(-120)
    counter.paletteIndex = 1
    context.insert(counter)
  }

  private static func seedMoneyCounter(in context: ModelContext) {
    let counter = CustomCounter(
      name: "Money",
      unit: CounterTemplate.money.defaultUnit,
      buttonValues: CounterTemplate.money.defaultPresets,
      goal: 3000,
      goalDirection: .countDown,
      sortOrder: 2
    )
    counter.createdAt = .now.addingTimeInterval(-60)
    counter.paletteIndex = 2
    context.insert(counter)
  }
}
