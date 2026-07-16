import Foundation
import SwiftData
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

enum WatchSyncEngine {
  static var isApplyingRemoteChanges = false

  @MainActor
  static func publishFullSnapshot(in context: ModelContext) {
    guard !isApplyingRemoteChanges else { return }

    let counters = ((try? context.fetch(FetchDescriptor<CustomCounter>())) ?? [])
      .map(CounterSnapshot.init(counter:))
    let entries = ((try? context.fetch(FetchDescriptor<CounterEntry>())) ?? [])
      .compactMap { entry -> EntrySnapshot? in
        guard let counterID = entry.counter?.id else { return nil }
        return EntrySnapshot(entry: entry, counterID: counterID)
      }

    send(
      WatchSyncPayload.fullSnapshot(counters: counters, entries: entries)
    )
  }

  @MainActor
  static func send(_ payload: WatchSyncPayload) {
    #if canImport(WatchConnectivity)
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    guard session.activationState == .activated else { return }

    let envelope = WatchSyncEnvelope(payload: payload, sentAt: .now)
    guard let message = WatchSyncCoding.encode(envelope) else { return }

    switch payload {
    case .fullSnapshot:
      try? session.updateApplicationContext(message)
      if session.isReachable {
        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
      }

    default:
      if session.isReachable {
        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
      } else {
        session.transferUserInfo(message)
      }
    }
    #endif
  }

  nonisolated static func handleIncoming(_ message: [String: Any]) {
    guard let data = message["watchSync"] as? Data else { return }
    Task { @MainActor in
      guard let envelope = try? JSONDecoder().decode(WatchSyncEnvelope.self, from: data) else { return }
      apply(envelope, in: SharedModelContainer.shared.mainContext)
    }
  }

  @MainActor
  static func publishCounterUpsert(_ counter: CustomCounter) {
    guard !isApplyingRemoteChanges else { return }
    send(
      WatchSyncPayload.upsertCounter(CounterSnapshot(counter: counter))
    )
  }

  @MainActor
  static func publishCounterDelete(_ id: UUID) {
    guard !isApplyingRemoteChanges else { return }
    send(.deleteCounter(id))
  }

  @MainActor
  static func publishEntryUpsert(_ entry: CounterEntry) {
    guard !isApplyingRemoteChanges else { return }
    guard let counterID = entry.counter?.id else { return }
    send(
      WatchSyncPayload.upsertEntry(EntrySnapshot(entry: entry, counterID: counterID))
    )
  }

  @MainActor
  static func publishEntryDelete(_ id: UUID) {
    guard !isApplyingRemoteChanges else { return }
    send(.deleteEntry(id))
  }

  @MainActor
  static func publishResetAll() {
    guard !isApplyingRemoteChanges else { return }
    send(.resetAll)
  }

  @MainActor
  static func apply(_ envelope: WatchSyncEnvelope, in context: ModelContext) {
    isApplyingRemoteChanges = true
    defer { isApplyingRemoteChanges = false }

    switch envelope.payload {
    case let .fullSnapshot(counters, entries):
      for snapshot in counters {
        CounterSnapshot.upsert(into: context, from: snapshot)
      }
      for snapshot in entries {
        EntrySnapshot.upsert(into: context, from: snapshot)
      }

    case let .upsertCounter(snapshot):
      CounterSnapshot.upsert(into: context, from: snapshot)

    case let .deleteCounter(id):
      if let counter = CounterSnapshot.fetchCounter(id: id, in: context) {
        context.delete(counter)
      }

    case let .upsertEntry(snapshot):
      EntrySnapshot.upsert(into: context, from: snapshot)

    case let .deleteEntry(id):
      if let entry = EntrySnapshot.fetchEntry(id: id, in: context) {
        context.delete(entry)
      }

    case .resetAll:
      deleteAllData(in: context)
    }

    AppLog.attempt("Save watch sync") { try context.save() }
    publishWidgetSnapshotIfNeeded(in: context)
  }

  @MainActor
  private static func deleteAllData(in context: ModelContext) {
    for counter in (try? context.fetch(FetchDescriptor<CustomCounter>())) ?? [] {
      context.delete(counter)
    }
    for entry in (try? context.fetch(FetchDescriptor<CounterEntry>())) ?? [] {
      context.delete(entry)
    }
    QuickAddSessionStore.shared.reset()
    WidgetSnapshot.clear()
    UserDefaults.standard.set(true, forKey: "app.data.suppressSampleSeeding")
  }

  @MainActor
  private static func publishWidgetSnapshotIfNeeded(in context: ModelContext) {
    #if os(iOS)
    var descriptor = FetchDescriptor<CustomCounter>(
      sortBy: [SortDescriptor(\.createdAt)]
    )
    descriptor.fetchLimit = 1
    if let counter = try? context.fetch(descriptor).first {
      WidgetSnapshot.publish(
        title: counter.name,
        heroValue: counter.currentProgress()?.heroValue ?? "\(counter.currentTotal())"
      )
    }
    #endif
  }
}
