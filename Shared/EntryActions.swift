import Foundation
import SwiftData

enum EntryActions {
  static let quickAddBatchInterval: TimeInterval = 2

  private enum QuickAddScope: Hashable {
    case calorie
    case counter(UUID)
  }

  private struct QuickAddSession {
    var entryID: UUID
    var lastTap: Date
  }

  @MainActor
  private static var quickAddSessions: [QuickAddScope: QuickAddSession] = [:]

  static func addCalorie(value: Int, in context: ModelContext) {
    let entry = CalorieEntry(value: value)
    context.insert(entry)
  }

  @MainActor
  static func addCalorieQuick(value: Int, in context: ModelContext) {
    let scope = QuickAddScope.calorie
    let now = Date.now

    if
      var session = quickAddSessions[scope],
      now.timeIntervalSince(session.lastTap) <= quickAddBatchInterval,
      let entry = fetchCalorieEntry(id: session.entryID, in: context)
    {
      entry.value += value
      session.lastTap = now
      quickAddSessions[scope] = session
      try? context.save()
      return
    }

    let entry = CalorieEntry(value: value)
    context.insert(entry)
    quickAddSessions[scope] = QuickAddSession(entryID: entry.id, lastTap: now)
  }

  static func addCounterEntry(value: Int, counter: CustomCounter, in context: ModelContext) {
    let entry = CounterEntry(value: value, counter: counter)
    context.insert(entry)
  }

  @MainActor
  static func addCounterEntryQuick(value: Int, counter: CustomCounter, in context: ModelContext) {
    let scope = QuickAddScope.counter(counter.id)
    let now = Date.now

    if
      var session = quickAddSessions[scope],
      now.timeIntervalSince(session.lastTap) <= quickAddBatchInterval,
      let entry = fetchCounterEntry(id: session.entryID, in: context)
    {
      entry.value += value
      session.lastTap = now
      quickAddSessions[scope] = session
      try? context.save()
      return
    }

    let entry = CounterEntry(value: value, counter: counter)
    context.insert(entry)
    quickAddSessions[scope] = QuickAddSession(entryID: entry.id, lastTap: now)
  }

  static func deleteCalorieEntry(id: UUID, in context: ModelContext) {
    guard let entry = fetchCalorieEntry(id: id, in: context) else { return }
    clearQuickAddSession(for: .calorie, entryID: id)
    context.delete(entry)
    try? context.save()
  }

  static func updateCalorieEntry(id: UUID, value: Int, in context: ModelContext) {
    guard let entry = fetchCalorieEntry(id: id, in: context) else { return }
    entry.value = value
    try? context.save()
  }

  static func deleteCounterEntry(id: UUID, in context: ModelContext) {
    guard let entry = fetchCounterEntry(id: id, in: context) else { return }
    if let counterID = entry.counter?.id {
      clearQuickAddSession(for: .counter(counterID), entryID: id)
    }
    context.delete(entry)
    try? context.save()
  }

  static func updateCounterEntry(id: UUID, value: Int, in context: ModelContext) {
    guard let entry = fetchCounterEntry(id: id, in: context) else { return }
    entry.value = value
    try? context.save()
  }

  private static func fetchCalorieEntry(id: UUID, in context: ModelContext) -> CalorieEntry? {
    var descriptor = FetchDescriptor<CalorieEntry>(
      predicate: #Predicate { $0.id == id }
    )
    descriptor.fetchLimit = 1
    return try? context.fetch(descriptor).first
  }

  private static func fetchCounterEntry(id: UUID, in context: ModelContext) -> CounterEntry? {
    var descriptor = FetchDescriptor<CounterEntry>(
      predicate: #Predicate { $0.id == id }
    )
    descriptor.fetchLimit = 1
    return try? context.fetch(descriptor).first
  }

  @MainActor
  private static func clearQuickAddSession(for scope: QuickAddScope, entryID: UUID) {
    guard quickAddSessions[scope]?.entryID == entryID else { return }
    quickAddSessions.removeValue(forKey: scope)
  }
}
