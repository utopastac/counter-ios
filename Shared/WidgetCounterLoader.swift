import Foundation
import SwiftData

enum WidgetCounterLoader {
  static func snapshot(for counterID: String, burned: Int = WidgetSnapshot.burned) -> CounterWidgetSnapshot {
    let context = ModelContext(SharedModelContainer.shared)

    if WidgetCounterID.isCalories(counterID) {
      return caloriesSnapshot(context: context, burned: burned)
    }

    guard
      let uuid = UUID(uuidString: counterID),
      let counter = fetchCounter(id: uuid, in: context)
    else {
      return .placeholder
    }

    return customCounterSnapshot(counter: counter, context: context)
  }

  @MainActor
  static func addEntryQuick(counterID: String, amount: Int, burned: Int = WidgetSnapshot.burned) {
    guard amount > 0 else { return }

    let context = ModelContext(SharedModelContainer.shared)

    if WidgetCounterID.isCalories(counterID) {
      EntryActions.addCalorieQuick(value: amount, in: context)
    } else if
      let uuid = UUID(uuidString: counterID),
      let counter = fetchCounter(id: uuid, in: context)
    {
      EntryActions.addCounterEntryQuick(value: amount, counter: counter, in: context)
    } else {
      return
    }

    try? context.save()
    WidgetSnapshotSync.publish(from: context, burned: burned)
  }

  private static func caloriesSnapshot(context: ModelContext, burned: Int) -> CounterWidgetSnapshot {
    let settings = fetchSettings(in: context)
    let entries = fetchCalorieEntries(in: context)
    let total = CounterPeriodCalculator.totalCalories(from: entries, for: settings)
    let progress = GoalProgressCalculator.progress(
      current: total,
      goal: settings.effectiveCalorieGoal,
      direction: settings.calorieGoalDirection
    )
    let ring = GoalProgressCalculator.ringDisplay(
      current: total,
      goal: settings.effectiveCalorieGoal,
      direction: settings.calorieGoalDirection
    )
    let buttons = QuickAddConfiguration.filledPresets(
      from: settings.calorieButtonValues,
      defaults: QuickAddConfiguration.defaultCaloriePresets
    )

    return CounterWidgetSnapshot(
      counterID: WidgetCounterID.calories,
      title: "Calories",
      paletteIndex: 0,
      heroValue: progress?.heroValue ?? "\(total)",
      heroCaption: progress?.heroCaption ?? "logged",
      ringFraction: ring.ringFraction,
      buttonValues: widgetButtonValues(from: buttons),
      lastUpdated: .now
    )
  }

  private static func customCounterSnapshot(
    counter: CustomCounter,
    context: ModelContext
  ) -> CounterWidgetSnapshot {
    let counters = fetchCounters(in: context)
    let paletteIndex = counters.firstIndex(where: { $0.id == counter.id })
      .map { WidgetPalette.paletteIndex(forCustomCounterAt: $0) } ?? 1
    let total = CounterPeriodCalculator.total(from: counter.entries, for: counter)
    let progress = GoalProgressCalculator.progress(
      current: total,
      goal: counter.effectiveGoal,
      direction: counter.goalDirection
    )
    let ring = GoalProgressCalculator.ringDisplay(
      current: total,
      goal: counter.effectiveGoal,
      direction: counter.goalDirection
    )
    let buttons = QuickAddConfiguration.filledPresets(
      from: counter.buttonValues,
      defaults: QuickAddConfiguration.defaultCounterPresets
    )

    return CounterWidgetSnapshot(
      counterID: counter.id.uuidString,
      title: counter.name,
      paletteIndex: paletteIndex,
      heroValue: progress?.heroValue ?? "\(total)",
      heroCaption: progress?.heroCaption ?? "logged",
      ringFraction: ring.ringFraction,
      buttonValues: widgetButtonValues(from: buttons),
      lastUpdated: .now
    )
  }

  private static func widgetButtonValues(from presets: [Int]) -> [Int] {
    var seen = Set<Int>()
    var values: [Int] = []

    for value in presets {
      guard values.count < 8 else { break }
      guard seen.insert(value).inserted else { continue }
      values.append(value)
    }

    return values
  }

  private static func fetchSettings(in context: ModelContext) -> AppSettings {
    var descriptor = FetchDescriptor<AppSettings>()
    descriptor.fetchLimit = 1
    return (try? context.fetch(descriptor).first) ?? AppSettings()
  }

  private static func fetchCalorieEntries(in context: ModelContext) -> [CalorieEntry] {
    (try? context.fetch(FetchDescriptor<CalorieEntry>())) ?? []
  }

  private static func fetchCounters(in context: ModelContext) -> [CustomCounter] {
    var descriptor = FetchDescriptor<CustomCounter>(
      sortBy: [SortDescriptor(\.createdAt)]
    )
    return (try? context.fetch(descriptor)) ?? []
  }

  private static func fetchCounter(id: UUID, in context: ModelContext) -> CustomCounter? {
    var descriptor = FetchDescriptor<CustomCounter>(
      predicate: #Predicate { $0.id == id }
    )
    descriptor.fetchLimit = 1
    return try? context.fetch(descriptor).first
  }
}
