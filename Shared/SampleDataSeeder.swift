import Foundation
import SwiftData

/// Seeds mock counters and entries from the design mockups when no counters exist.
enum SampleDataSeeder {
  /// Quick-add presets shown in the design mockups.
  static let mockQuickAddPresets: [Int] = QuickAddConfiguration.defaultCaloriePresets

  @MainActor
  static func seedIfNeeded(in context: ModelContext) {
    // Legacy calorie -> CustomCounter migration now runs automatically, once, at store-open
    // time via `CounterMigrationPlan` (see `SharedModelContainer`), so it doesn't need to be
    // re-checked here on every launch.
    migratePaletteIndicesIfNeeded(in: context)
    guard !UserDefaults.standard.bool(forKey: AppDataReset.suppressSampleSeedingKey) else { return }
    guard !hasAnyCounters(in: context) else { return }

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

  /// Calories mockup: target 2200, added −200, remaining 2420.
  private static func seedCaloriesCounter(in context: ModelContext) {
    let counter = CustomCounter(
      name: "Calories",
      buttonValues: mockQuickAddPresets,
      sliderMax: 2000,
      goal: CustomCounter.defaultCalorieGoal,
      goalDirection: .countDown
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
      buttonValues: mockQuickAddPresets,
      goal: 150,
      goalDirection: .countUp
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
      buttonValues: mockQuickAddPresets,
      goal: 3000,
      goalDirection: .countDown
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

  @MainActor
  private static func migratePaletteIndicesIfNeeded(in context: ModelContext) {
    guard !UserDefaults.standard.bool(forKey: paletteMigrationKey) else { return }

    var descriptor = FetchDescriptor<CustomCounter>(
      sortBy: [SortDescriptor(\.createdAt)]
    )
    let counters = (try? context.fetch(descriptor)) ?? []

    for (index, counter) in counters.enumerated() {
      counter.paletteIndex = CustomCounter.normalizedPaletteIndex(index)
    }

    AppLog.attempt("Save palette index migration") { try context.save() }
    UserDefaults.standard.set(true, forKey: paletteMigrationKey)
  }
}
