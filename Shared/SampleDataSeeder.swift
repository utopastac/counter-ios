import Foundation
import SwiftData

/// Seeds mock counters and entries from the design mockups when no counters exist.
enum SampleDataSeeder {
  /// Quick-add presets shown in the design mockups.
  static let mockQuickAddPresets: [Double] = QuickAddConfiguration.defaultCaloriePresets

  @MainActor
  static func seedIfNeeded(in context: ModelContext) {
    // Legacy calorie -> CustomCounter migration now runs automatically, once, at store-open
    // time via `CounterMigrationPlan` (see `SharedModelContainer`), so it doesn't need to be
    // re-checked here on every launch.
    migratePaletteIndicesIfNeeded(in: context)
    migrateSortOrderIfNeeded(in: context)
    migrateAmountsToHundredthsIfNeeded(in: context)
    guard !UserDefaults.standard.bool(forKey: AppDataReset.suppressSampleSeedingKey) else { return }
    guard !hasAnyCounters(in: context) else { return }

    seedCaloriesCounter(in: context)
    seedProteinCounter(in: context)
    seedMoneyCounter(in: context)

    AppLog.attempt("Save seeded sample data") { try context.save() }
    WatchSyncEngine.publishFullSnapshot(in: context)
  }

  private static func hasAnyCounters(in context: ModelContext) -> Bool {
    var descriptor = FetchDescriptor<CustomCounter>()
    descriptor.fetchLimit = 1
    return (try? context.fetch(descriptor).isEmpty == false) ?? false
  }

  /// Calories mockup: target 2200, added −200, remaining 2420.
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

    let timestamps = sampleTimestamps(count: 5)
    for timestamp in timestamps {
      let entry = CounterEntry(value: -40, timestamp: timestamp, counter: counter)
      context.insert(entry)
    }
  }

  /// Protein mockup: target 150, added 70, 80 to go (count up).
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

    let timestamps = sampleTimestamps(count: 7)
    for timestamp in timestamps {
      let entry = CounterEntry(value: 10, timestamp: timestamp, counter: counter)
      context.insert(entry)
    }
  }

  /// Money mockup: target 3000, added 480, remaining 2520 (count down).
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

    let timestamps = sampleTimestamps(count: 5)
    for timestamp in timestamps {
      let entry = CounterEntry(value: 96, timestamp: timestamp, counter: counter)
      context.insert(entry)
    }
  }

  private static func sampleTimestamps(count: Int, base: Date = .now) -> [Date] {
    (0..<count).map { index in
      base.addingTimeInterval(TimeInterval(-index * 60))
    }
  }

  private static let paletteMigrationKey = "counterPaletteIndexMigrated"
  private static let sortOrderMigrationKey = "counterSortOrderMigrated"
  static let hundredthsMigrationKey = "counterAmountsAreHundredths"

  @MainActor
  private static func migratePaletteIndicesIfNeeded(in context: ModelContext) {
    guard !UserDefaults.standard.bool(forKey: paletteMigrationKey) else { return }

    let descriptor = FetchDescriptor<CustomCounter>(
      sortBy: [SortDescriptor(\.createdAt)]
    )
    let counters = (try? context.fetch(descriptor)) ?? []

    for (index, counter) in counters.enumerated() {
      counter.paletteIndex = CustomCounter.normalizedPaletteIndex(index)
    }

    AppLog.attempt("Save palette index migration") { try context.save() }
    UserDefaults.standard.set(true, forKey: paletteMigrationKey)
  }

  /// After V2→V3, existing counters may all have `sortOrder == 0`. Seed from `createdAt`
  /// once so pager/list order matches the previous creation order.
  @MainActor
  private static func migrateSortOrderIfNeeded(in context: ModelContext) {
    guard !UserDefaults.standard.bool(forKey: sortOrderMigrationKey) else { return }

    let descriptor = FetchDescriptor<CustomCounter>(
      sortBy: [SortDescriptor(\.createdAt)]
    )
    let counters = (try? context.fetch(descriptor)) ?? []
    let allZero = counters.allSatisfy { $0.sortOrder == 0 }
    guard allZero, counters.count > 1 else {
      UserDefaults.standard.set(true, forKey: sortOrderMigrationKey)
      return
    }

    for (index, counter) in counters.enumerated() {
      counter.sortOrder = Double(index)
    }

    AppLog.attempt("Save sort order migration") { try context.save() }
    UserDefaults.standard.set(true, forKey: sortOrderMigrationKey)
  }

  /// Whole-number Int amounts shipped before decimals. Multiply by 100 once so storage
  /// matches `CounterAmount` hundredths (2200 → 220_000 = 2200.00).
  @MainActor
  private static func migrateAmountsToHundredthsIfNeeded(in context: ModelContext) {
    guard !UserDefaults.standard.bool(forKey: hundredthsMigrationKey) else { return }

    let counters = (try? context.fetch(FetchDescriptor<CustomCounter>())) ?? []
    for counter in counters {
      counter.buttonValues = counter.buttonValues.map { $0 * CounterAmount.scale }
      counter.sliderMax *= CounterAmount.scale
      if let goal = counter.goal {
        counter.goal = goal * CounterAmount.scale
      }
      for entry in counter.entries {
        entry.value *= CounterAmount.scale
      }
    }

    AppLog.attempt("Save hundredths amount migration") { try context.save() }
    UserDefaults.standard.set(true, forKey: hundredthsMigrationKey)
  }
}
