import Foundation
import SwiftData

/// Seeds mock counters and entries from the design mockups when no counters exist.
enum SampleDataSeeder {
  /// Quick-add presets shown in the design mockups.
  static let mockQuickAddPresets: [Double] = QuickAddConfiguration.defaultCaloriePresets

  @MainActor
  static func seedIfNeeded(in context: ModelContext) {
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
}
