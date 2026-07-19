import Foundation
import SwiftData

enum WidgetCounterLoader {
  static func snapshot(for counterID: String) -> CounterWidgetSnapshot {
    // Gallery / WidgetKit placeholder id — keep the sample layout.
    if counterID == "preview" {
      return .placeholder
    }

    guard
      let uuid = UUID(uuidString: counterID)
    else {
      return .unavailable
    }

    let context = ModelContext(SharedModelContainer.shared)
    guard let counter = fetchCounter(id: uuid, in: context) else {
      return .unavailable
    }

    return counterSnapshot(counter: counter, context: context)
  }

  @MainActor
  static func addEntryQuick(counterID: String, amount: Double) {
    guard amount > 0 else { return }

    let context = ModelContext(SharedModelContainer.shared)

    guard
      let uuid = UUID(uuidString: counterID),
      let counter = fetchCounter(id: uuid, in: context)
    else {
      return
    }

    QuickAddSessionStore.shared.addCounterEntryQuick(value: amount, counter: counter, in: context)
    AppLog.attempt("Save widget quick-add") { try context.save() }
    WidgetSnapshot.reloadTimelines()
  }

  private static func counterSnapshot(
    counter: CustomCounter,
    context: ModelContext
  ) -> CounterWidgetSnapshot {
    let paletteIndex = AppAppearancePreference.resolvedPaletteIndex(counter.effectivePaletteIndex)
    let total = counter.currentTotal()
    let progress = counter.currentProgress()
    let buttons = QuickAddConfiguration.filledPresets(
      from: counter.presetAmounts,
      defaults: QuickAddConfiguration.defaultPresets(forCounterNamed: counter.name)
    )

    return CounterWidgetSnapshot(
      counterID: counter.id.uuidString,
      title: counter.name,
      paletteIndex: paletteIndex,
      heroValue: progress?.heroValue ?? CounterFormatting.amount(total),
      heroSubtitle: progress?.heroSubtitle.capitalized ?? counter.resetPeriod.periodCaption.capitalized,
      ringProgress: progress,
      buttonValues: widgetButtonValues(from: buttons),
      lastUpdated: .now,
      isUnavailable: false
    )
  }

  private static func widgetButtonValues(from presets: [Double]) -> [Double] {
    var seen = Set<Double>()
    var values: [Double] = []

    for value in presets {
      guard values.count < 8 else { break }
      guard seen.insert(value).inserted else { continue }
      values.append(value)
    }

    return values
  }

  private static func fetchCounters(in context: ModelContext) -> [CustomCounter] {
    let descriptor = FetchDescriptor<CustomCounter>(
      sortBy: [SortDescriptor(\.sortOrder)]
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

  @MainActor
  static func defaultCounterID() -> String? {
    let context = ModelContext(SharedModelContainer.shared)
    let counters = fetchCounters(in: context)
    return counters.first?.id.uuidString
  }
}
