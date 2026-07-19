import Foundation
import SwiftData

struct CounterSnapshot: Codable, Sendable, Equatable {
  let id: UUID
  let name: String
  let unit: String
  let buttonValues: [Double]
  let sliderMax: Double
  let createdAt: Date
  let sortOrder: Double
  let goal: Double?
  let resetPeriodRaw: String
  let resetAnchorDay: Int
  let goalDirectionRaw: String
  let paletteIndex: Int

  init(counter: CustomCounter) {
    id = counter.id
    name = counter.name
    unit = counter.unit
    buttonValues = counter.presetAmounts
    sliderMax = counter.effectiveSliderMax
    createdAt = counter.createdAt
    sortOrder = counter.sortOrder
    goal = counter.effectiveGoal
    resetPeriodRaw = counter.resetPeriodRaw
    resetAnchorDay = counter.resetAnchorDay
    goalDirectionRaw = counter.goalDirectionRaw
    paletteIndex = counter.paletteIndex
  }

  @MainActor
  func apply(to counter: CustomCounter) {
    counter.name = name
    counter.unit = unit
    counter.presetAmounts = buttonValues
    counter.sliderMax = CounterAmount.rounded(sliderMax)
    counter.createdAt = createdAt
    counter.sortOrder = sortOrder
    counter.goal = goal.map(CounterAmount.rounded)
    counter.resetPeriodRaw = resetPeriodRaw
    counter.resetAnchorDay = resetAnchorDay
    counter.goalDirectionRaw = goalDirectionRaw
    counter.paletteIndex = paletteIndex
  }

  @MainActor
  @discardableResult
  static func upsert(into context: ModelContext, from snapshot: CounterSnapshot) -> CustomCounter {
    if let existing = fetchCounter(id: snapshot.id, in: context) {
      snapshot.apply(to: existing)
      return existing
    }

    let counter = CustomCounter(
      name: snapshot.name,
      unit: snapshot.unit,
      buttonValues: snapshot.buttonValues,
      sliderMax: snapshot.sliderMax,
      goal: snapshot.goal,
      resetPeriod: CounterResetPeriod(rawValue: snapshot.resetPeriodRaw) ?? .daily,
      resetAnchorDay: snapshot.resetAnchorDay,
      goalDirection: GoalDirection(rawValue: snapshot.goalDirectionRaw) ?? .countUp,
      paletteIndex: snapshot.paletteIndex,
      sortOrder: snapshot.sortOrder
    )
    counter.id = snapshot.id
    counter.createdAt = snapshot.createdAt
    context.insert(counter)
    return counter
  }

  @MainActor
  static func fetchCounter(id: UUID, in context: ModelContext) -> CustomCounter? {
    var descriptor = FetchDescriptor<CustomCounter>(
      predicate: #Predicate { $0.id == id }
    )
    descriptor.fetchLimit = 1
    return try? context.fetch(descriptor).first
  }
}

struct EntrySnapshot: Codable, Sendable, Equatable {
  let id: UUID
  let counterID: UUID
  let value: Double
  let timestamp: Date

  init(entry: CounterEntry, counterID: UUID) {
    id = entry.id
    self.counterID = counterID
    value = entry.amount
    timestamp = entry.timestamp
  }

  @MainActor
  @discardableResult
  static func upsert(into context: ModelContext, from snapshot: EntrySnapshot) -> CounterEntry? {
    guard let counter = CounterSnapshot.fetchCounter(id: snapshot.counterID, in: context) else {
      return nil
    }

    if let existing = fetchEntry(id: snapshot.id, in: context) {
      existing.amount = snapshot.value
      existing.timestamp = snapshot.timestamp
      existing.counter = counter
      return existing
    }

    let entry = CounterEntry(value: snapshot.value, timestamp: snapshot.timestamp, counter: counter)
    entry.id = snapshot.id
    context.insert(entry)
    return entry
  }

  @MainActor
  static func fetchEntry(id: UUID, in context: ModelContext) -> CounterEntry? {
    EntryActions.fetchCounterEntry(id: id, in: context)
  }
}

enum WatchSyncPayload: Codable, Sendable {
  case fullSnapshot(counters: [CounterSnapshot], entries: [EntrySnapshot])
  case upsertCounter(CounterSnapshot)
  case deleteCounter(UUID)
  case upsertEntry(EntrySnapshot)
  case deleteEntry(UUID)
  case resetAll
}

struct WatchSyncEnvelope: Codable, Sendable {
  let payload: WatchSyncPayload
  let sentAt: Date
}

enum WatchSyncCoding {
  static let messageKey = "watchSync"

  @MainActor
  static func encode(_ envelope: WatchSyncEnvelope) -> [String: Any]? {
    guard let data = try? JSONEncoder().encode(envelope) else { return nil }
    return [messageKey: data]
  }

  @MainActor
  static func decode(_ message: [String: Any]) -> WatchSyncEnvelope? {
    guard let data = message[messageKey] as? Data else { return nil }
    return try? JSONDecoder().decode(WatchSyncEnvelope.self, from: data)
  }
}
