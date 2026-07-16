import Foundation
import SwiftData

/// Stateless CRUD for `CounterEntry`. Quick-add batching (accumulating rapid taps into one
/// entry) is handled separately by `QuickAddSessionStore`, which owns the mutable state that
/// used to live here as a hidden `private static var` — see that type's doc comment for why.
enum EntryActions {
  /// How long the entry-added toast remains visible after the last update.
  static let entryToastDuration: TimeInterval = 3

  struct AddedEntry: Equatable {
    let entryID: UUID
    let value: Int
  }

  @discardableResult
  @MainActor
  static func addCounterEntry(value: Int, counter: CustomCounter, in context: ModelContext) -> AddedEntry {
    let entry = CounterEntry(value: value, counter: counter)
    context.insert(entry)
    WatchSyncEngine.publishEntryUpsert(entry)
    return AddedEntry(entryID: entry.id, value: entry.value)
  }

  @MainActor
  static func deleteCounterEntry(id: UUID, in context: ModelContext) {
    guard let entry = fetchCounterEntry(id: id, in: context) else { return }
    context.delete(entry)
    AppLog.attempt("Save entry deletion") { try context.save() }
    WatchSyncEngine.publishEntryDelete(id)
  }

  @MainActor
  static func updateCounterEntry(id: UUID, value: Int, in context: ModelContext) {
    guard let entry = fetchCounterEntry(id: id, in: context) else { return }
    entry.value = value
    AppLog.attempt("Save entry update") { try context.save() }
    WatchSyncEngine.publishEntryUpsert(entry)
  }

  /// Not `private`: `QuickAddSessionStore` looks up the entry a batching window is tracking
  /// by id from a different file, and needs this same lookup.
  static func fetchCounterEntry(id: UUID, in context: ModelContext) -> CounterEntry? {
    var descriptor = FetchDescriptor<CounterEntry>(
      predicate: #Predicate { $0.id == id }
    )
    descriptor.fetchLimit = 1
    return try? context.fetch(descriptor).first
  }
}
