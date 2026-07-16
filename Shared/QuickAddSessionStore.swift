import Foundation
import SwiftData

/// Batches rapid taps on the same quick-add button into a single `CounterEntry` instead of
/// creating one row per tap: a second tap within `batchInterval` of the first accumulates
/// onto the entry that tap created rather than inserting a new one.
///
/// This is deliberately a real, referenceable type with instance state rather than a
/// `private static var` hidden inside an otherwise-stateless enum. Call sites that have a
/// natural owner for this state hold their own instance scoped to that owner's lifetime:
///
/// - `CustomCounterPageContent` and `WatchCounterDetailView` each keep one in `@State`,
///   scoped to that counter page's lifetime — when the page goes away, so does its batching
///   window, which is the correct behavior (a stale window shouldn't outlive the screen that
///   created it).
/// - The widget extension's `AddCounterEntryIntent` has no such owner — each intent
///   invocation is handled by whichever process the system currently has running, with no
///   view to attach state to — so it explicitly opts into `QuickAddSessionStore.shared`
///   instead. This is the one legitimate use of a singleton here, and it's now visible and
///   named rather than smuggled into `EntryActions`.
///
/// A session referencing an entry that no longer exists (e.g. deleted from the entry log
/// while a batching window was still open) self-heals on the next quick-add: `fetchCounterEntry`
/// returns `nil`, so the batch falls through to inserting a fresh entry.
@MainActor
final class QuickAddSessionStore {
  static let shared = QuickAddSessionStore()

  static var batchInterval: TimeInterval {
    AppAppearancePreference.quickAddBatchInterval
  }

  private struct Session {
    var entryID: UUID
    var lastTap: Date
  }

  private var sessionsByCounterID: [UUID: Session] = [:]

  init() {}

  @discardableResult
  func addCounterEntryQuick(value: Int, counter: CustomCounter, in context: ModelContext) -> EntryActions.AddedEntry {
    let now = Date.now

    if
      let session = sessionsByCounterID[counter.id],
      now.timeIntervalSince(session.lastTap) <= Self.batchInterval,
      let entry = EntryActions.fetchCounterEntry(id: session.entryID, in: context)
    {
      entry.value += value
      sessionsByCounterID[counter.id] = Session(entryID: entry.id, lastTap: now)
      AppLog.attempt("Save quick-add batch") { try context.save() }
      WatchSyncEngine.publishEntryUpsert(entry)
      return EntryActions.AddedEntry(entryID: entry.id, value: entry.value)
    }

    let entry = CounterEntry(value: value, counter: counter)
    context.insert(entry)
    sessionsByCounterID[counter.id] = Session(entryID: entry.id, lastTap: now)
    WatchSyncEngine.publishEntryUpsert(entry)
    return EntryActions.AddedEntry(entryID: entry.id, value: entry.value)
  }

  /// Drops every in-flight batching window. Used after a full data reset so `.shared`
  /// doesn't hold onto session state for counters that no longer exist.
  func reset() {
    sessionsByCounterID.removeAll()
  }
}
