import Foundation
import SwiftData

enum EntryActions {
  static let quickAddBatchInterval: TimeInterval = 2
  /// How long the entry-added toast remains visible after the last update.
  static let entryToastDuration: TimeInterval = 3

  struct AddedEntry: Equatable {
    let entryID: UUID
    let value: Int
  }

  private enum QuickAddScope: Hashable {
    case counter(UUID)
  }

  private struct QuickAddSession {
    var entryID: UUID
    var lastTap: Date
  }

  @MainActor
  private static var quickAddSessions: [QuickAddScope: QuickAddSession] = [:]

  @discardableResult
  static func addCounterEntry(value: Int, counter: CustomCounter, in context: ModelContext) -> AddedEntry {
    let entry = CounterEntry(value: value, counter: counter)
    context.insert(entry)
    return AddedEntry(entryID: entry.id, value: entry.value)
  }

  @MainActor
  @discardableResult
  static func addCounterEntryQuick(value: Int, counter: CustomCounter, in context: ModelContext) -> AddedEntry {
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
      return AddedEntry(entryID: entry.id, value: entry.value)
    }

    let entry = CounterEntry(value: value, counter: counter)
    context.insert(entry)
    quickAddSessions[scope] = QuickAddSession(entryID: entry.id, lastTap: now)
    return AddedEntry(entryID: entry.id, value: entry.value)
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

  @MainActor
  static func clearAllQuickAddSessions() {
    quickAddSessions.removeAll()
  }
}
