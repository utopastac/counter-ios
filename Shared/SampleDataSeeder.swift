import Foundation
import SwiftData

/// Seeds mock counters and entries from the design mockups when no custom counters exist.
enum SampleDataSeeder {
  /// Quick-add presets shown in the design mockups.
  static let mockQuickAddPresets: [Int] = QuickAddConfiguration.defaultCaloriePresets

  @MainActor
  static func seedIfNeeded(in context: ModelContext) {
    guard !hasCustomCounters(in: context) else { return }

    seedSettings(in: context)

    if !hasCalorieEntries(in: context) {
      seedCalorieEntries(in: context)
    }

    seedProteinCounter(in: context)
    seedMoneyCounter(in: context)

    try? context.save()
  }

  private static func hasCustomCounters(in context: ModelContext) -> Bool {
    var descriptor = FetchDescriptor<CustomCounter>()
    descriptor.fetchLimit = 1
    return (try? context.fetch(descriptor).isEmpty == false) ?? false
  }

  private static func hasCalorieEntries(in context: ModelContext) -> Bool {
    var descriptor = FetchDescriptor<CalorieEntry>()
    descriptor.fetchLimit = 1
    return (try? context.fetch(descriptor).isEmpty == false) ?? false
  }

  private static func seedSettings(in context: ModelContext) {
    var descriptor = FetchDescriptor<AppSettings>()
    descriptor.fetchLimit = 1

    if let settings = try? context.fetch(descriptor).first {
      settings.calorieGoal = AppSettings.defaultCalorieGoal
      settings.calorieGoalDirection = .countDown
      settings.calorieButtonValues = mockQuickAddPresets
    } else {
      context.insert(
        AppSettings(
          calorieButtonValues: mockQuickAddPresets,
          calorieGoal: AppSettings.defaultCalorieGoal,
          calorieGoalDirection: .countDown
        )
      )
    }
  }

  /// Calories mockup: target 2200, added −200, remaining 2420.
  private static func seedCalorieEntries(in context: ModelContext) {
    let timestamps = sampleTimestamps(count: 5)
    for timestamp in timestamps {
      context.insert(CalorieEntry(value: -40, timestamp: timestamp))
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
