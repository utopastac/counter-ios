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
    let value: Double
  }

  /// Enough of a deleted entry to put it back from the undo toast, including a trashed media file.
  struct RemovedEntryRecord: Equatable {
    let entryID: UUID
    let value: Double
    let timestamp: Date
    let noteText: String
    let mediaRelativePath: String
    let latitude: Double?
    let longitude: Double?
  }

  @discardableResult
  @MainActor
  static func addCounterEntry(value: Double, counter: CustomCounter, in context: ModelContext) -> AddedEntry {
    let entry = CounterEntry(value: value, counter: counter)
    context.insert(entry)
    WatchSyncEngine.publishEntryUpsert(entry)
    return AddedEntry(entryID: entry.id, value: entry.amount)
  }

  @discardableResult
  @MainActor
  static func addNoteEntry(
    text: String,
    counter: CustomCounter,
    in context: ModelContext
  ) -> AddedEntry? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, counter.acceptsAnotherEntry() else { return nil }
    let entry = CounterEntry(value: 1, counter: counter)
    entry.noteText = trimmed
    context.insert(entry)
    WatchSyncEngine.publishEntryUpsert(entry)
    return AddedEntry(entryID: entry.id, value: entry.amount)
  }

  @discardableResult
  @MainActor
  static func addMediaEntry(
    data: Data,
    fileExtension: String,
    counter: CustomCounter,
    noteText: String = "",
    in context: ModelContext
  ) -> AddedEntry? {
    guard !data.isEmpty, counter.acceptsAnotherEntry() else { return nil }
    let entry = CounterEntry(value: 1, counter: counter)
    let relative = JournalMediaStore.save(data: data, entryID: entry.id, fileExtension: fileExtension)
    guard !relative.isEmpty else { return nil }
    entry.mediaRelativePath = relative
    entry.noteText = noteText
    context.insert(entry)
    WatchSyncEngine.publishEntryUpsert(entry)
    return AddedEntry(entryID: entry.id, value: entry.amount)
  }

  @discardableResult
  @MainActor
  static func addPlaceEntry(
    latitude: Double,
    longitude: Double,
    counter: CustomCounter,
    in context: ModelContext
  ) -> AddedEntry? {
    guard counter.acceptsAnotherEntry() else { return nil }
    let entry = CounterEntry(value: 1, counter: counter)
    entry.latitude = latitude
    entry.longitude = longitude
    context.insert(entry)
    WatchSyncEngine.publishEntryUpsert(entry)
    return AddedEntry(entryID: entry.id, value: entry.amount)
  }

  @MainActor
  static func deleteCounterEntry(id: UUID, in context: ModelContext) {
    guard let entry = fetchCounterEntry(id: id, in: context) else { return }
    JournalMediaStore.delete(relativePath: entry.mediaRelativePath)
    context.delete(entry)
    AppLog.attempt("Save entry deletion") { try context.save() }
    WatchSyncEngine.publishEntryDelete(id)
  }

  /// Deletes the row and moves its file to trash so the undo toast can restore both.
  @MainActor
  static func removeCounterEntryForUndo(id: UUID, in context: ModelContext) -> RemovedEntryRecord? {
    guard let entry = fetchCounterEntry(id: id, in: context) else { return nil }
    let record = RemovedEntryRecord(
      entryID: entry.id,
      value: entry.amount,
      timestamp: entry.timestamp,
      noteText: entry.noteText,
      mediaRelativePath: JournalMediaStore.trash(relativePath: entry.mediaRelativePath),
      latitude: entry.latitude,
      longitude: entry.longitude
    )
    context.delete(entry)
    AppLog.attempt("Save entry deletion") { try context.save() }
    WatchSyncEngine.publishEntryDelete(id)
    return record
  }

  @MainActor
  static func deleteCounter(_ counter: CustomCounter, in context: ModelContext) {
    JournalMediaStore.deleteFiles(for: counter)
    let id = counter.id
    context.delete(counter)
    AppLog.attempt("Save counter deletion") { try context.save() }
    WatchSyncEngine.publishCounterDelete(id)
  }

  @MainActor
  static func updateCounterEntry(id: UUID, value: Double, in context: ModelContext) {
    guard let entry = fetchCounterEntry(id: id, in: context) else { return }
    entry.amount = value
    AppLog.attempt("Save entry update") { try context.save() }
    WatchSyncEngine.publishEntryUpsert(entry)
  }

  /// Re-inserts a previously deleted entry with its original id/timestamp — used by the
  /// entry-log "removed" toast undo path.
  @discardableResult
  @MainActor
  static func restoreCounterEntry(
    id: UUID,
    value: Double,
    timestamp: Date,
    counter: CustomCounter,
    noteText: String = "",
    mediaRelativePath: String = "",
    latitude: Double? = nil,
    longitude: Double? = nil,
    in context: ModelContext
  ) -> AddedEntry {
    let entry = CounterEntry(value: value, timestamp: timestamp, counter: counter)
    entry.id = id
    entry.noteText = noteText
    entry.mediaRelativePath = mediaRelativePath
    entry.latitude = latitude
    entry.longitude = longitude
    context.insert(entry)
    AppLog.attempt("Save entry restore") { try context.save() }
    WatchSyncEngine.publishEntryUpsert(entry)
    return AddedEntry(entryID: entry.id, value: entry.amount)
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
