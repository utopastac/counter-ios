import Foundation
import SwiftData

enum WidgetCounterLoader {
  static func snapshot(for counterID: String) -> CounterWidgetSnapshot {
    let context = ModelContext(SharedModelContainer.shared)

    guard
      let uuid = UUID(uuidString: counterID),
      let counter = fetchCounter(id: uuid, in: context)
    else {
      return .placeholder
    }

    return counterSnapshot(counter: counter, context: context)
  }

  @MainActor
  static func addEntryQuick(counterID: String, amount: Int) {
    guard amount > 0 else { return }

    let context = ModelContext(SharedModelContainer.shared)

    guard
      let uuid = UUID(uuidString: counterID),
      let counter = fetchCounter(id: uuid, in: context)
    else {
      return
    }

    EntryActions.addCounterEntryQuick(value: amount, counter: counter, in: context)
    AppLog.attempt("Save widget quick-add") { try context.save() }
    WidgetSnapshot.reloadTimelines()
  }

  private static func counterSnapshot(
    counter: CustomCounter,
    context: ModelContext
  ) -> CounterWidgetSnapshot {
    let paletteIndex = counter.effectivePaletteIndex
    let total = counter.currentTotal()
    let progress = counter.currentProgress()
    let ring = counter.currentRingDisplay()
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

  @MainActor
  static func defaultCounterID() -> String? {
    let context = ModelContext(SharedModelContainer.shared)
    var descriptor = FetchDescriptor<CustomCounter>(
      sortBy: [SortDescriptor(\.createdAt)]
    )
    descriptor.fetchLimit = 1
    return try? context.fetch(descriptor).first?.id.uuidString
  }
}
