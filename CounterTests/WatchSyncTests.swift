import Foundation
import SwiftData
import Testing

/// Serialized because apply paths touch process-wide `QuickAddSessionStore` / widget defaults.
@Suite(.serialized)
@MainActor
struct WatchSyncTests {
  /// Keep the container alive for the duration of the test — `ModelContext(container)` retains
  /// it, but `container.mainContext` does not, and dropping the container mid-test traps.
  private func makeStore() -> (ModelContainer, ModelContext) {
    let container = TestModelContainer.make()
    return (container, ModelContext(container))
  }

  private func fixedCounter(
    name: String = "Water",
    unit: String = "ml",
    goal: Double? = 2000,
    resetPeriod: CounterResetPeriod = .yearly,
    resetAnchorDay: Int = 3,
    goalDirection: GoalDirection = .countUp,
    paletteIndex: Int = 2,
    id: UUID = UUID()
  ) -> CustomCounter {
    let counter = CustomCounter(
      name: name,
      unit: unit,
      goal: goal,
      resetPeriod: resetPeriod,
      resetAnchorDay: resetAnchorDay,
      goalDirection: goalDirection,
      paletteIndex: paletteIndex,
      sortOrder: 1
    )
    counter.id = id
    return counter
  }

  // MARK: - Encoding

  @Test func encodeDecodeRoundTripsEveryPayloadCase() throws {
    let counter = fixedCounter(id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!)
    let counterSnapshot = CounterSnapshot(counter: counter)
    let entry = CounterEntry(
      value: 12.5,
      timestamp: Date(timeIntervalSince1970: 1_700_000_000),
      counter: counter
    )
    entry.id = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
    let entrySnapshot = EntrySnapshot(entry: entry, counterID: counter.id)
    let sentAt = Date(timeIntervalSince1970: 100)

    let payloads: [WatchSyncPayload] = [
      .fullSnapshot(counters: [counterSnapshot], entries: [entrySnapshot]),
      .upsertCounter(counterSnapshot),
      .deleteCounter(counter.id),
      .upsertEntry(entrySnapshot),
      .deleteEntry(entry.id),
      .resetAll
    ]

    for payload in payloads {
      let envelope = WatchSyncEnvelope(payload: payload, sentAt: sentAt)
      let encoded = try #require(WatchSyncCoding.encode(envelope))
      let decoded = try #require(WatchSyncCoding.decode(encoded))

      #expect(decoded.sentAt == sentAt)
      assertPayload(decoded.payload, matches: payload)
    }
  }

  private func assertPayload(_ actual: WatchSyncPayload, matches expected: WatchSyncPayload) {
    switch (expected, actual) {
    case let (.fullSnapshot(expectedCounters, expectedEntries), .fullSnapshot(actualCounters, actualEntries)):
      #expect(actualCounters == expectedCounters)
      #expect(actualEntries == expectedEntries)
    case let (.upsertCounter(expectedCounter), .upsertCounter(actualCounter)):
      #expect(actualCounter == expectedCounter)
    case let (.deleteCounter(expectedID), .deleteCounter(actualID)):
      #expect(actualID == expectedID)
    case let (.upsertEntry(expectedEntry), .upsertEntry(actualEntry)):
      #expect(actualEntry == expectedEntry)
    case let (.deleteEntry(expectedID), .deleteEntry(actualID)):
      #expect(actualID == expectedID)
    case (.resetAll, .resetAll):
      break
    default:
      Issue.record("Payload case mismatch: \(expected) vs \(actual)")
    }
  }

  @Test func decodeRejectsMessagesWithoutWatchSyncKey() {
    #expect(WatchSyncCoding.decode(["other": Data()]) == nil)
  }

  // MARK: - Snapshot upsert

  @Test func counterSnapshotUpsertInsertsThenUpdatesInPlace() throws {
    let (container, context) = makeStore()
    defer { _ = container }

    let id = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
    let original = fixedCounter(name: "Water", goal: 2000, id: id)

    CounterSnapshot.upsert(into: context, from: CounterSnapshot(counter: original))
    try context.save()

    var counters = try context.fetch(FetchDescriptor<CustomCounter>())
    #expect(counters.count == 1)
    #expect(counters[0].id == id)
    #expect(counters[0].name == "Water")
    #expect(counters[0].goal == 2000)
    #expect(counters[0].resetPeriod == .yearly)
    #expect(counters[0].resetAnchorDay == 3)

    let renamed = fixedCounter(name: "H2O", goal: 2500, id: id)
    CounterSnapshot.upsert(into: context, from: CounterSnapshot(counter: renamed))
    try context.save()

    counters = try context.fetch(FetchDescriptor<CustomCounter>())
    #expect(counters.count == 1)
    #expect(counters[0].name == "H2O")
    #expect(counters[0].goal == 2500)
  }

  @Test func entrySnapshotUpsertRequiresMatchingCounter() throws {
    let (container, context) = makeStore()
    defer { _ = container }

    let counter = fixedCounter()
    let entry = CounterEntry(value: 5, timestamp: Date(timeIntervalSince1970: 50), counter: counter)
    entry.id = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
    let orphan = EntrySnapshot(entry: entry, counterID: UUID())

    #expect(EntrySnapshot.upsert(into: context, from: orphan) == nil)
    #expect(try context.fetch(FetchDescriptor<CounterEntry>()).isEmpty)
  }

  @Test func entrySnapshotUpsertInsertsAgainstExistingCounter() throws {
    let (container, context) = makeStore()
    defer { _ = container }

    let counter = fixedCounter(id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!)
    CounterSnapshot.upsert(into: context, from: CounterSnapshot(counter: counter))

    let entry = CounterEntry(
      value: 12.5,
      timestamp: Date(timeIntervalSince1970: 1_700_000_000),
      counter: counter
    )
    entry.id = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
    let snapshot = EntrySnapshot(entry: entry, counterID: counter.id)

    let upserted = EntrySnapshot.upsert(into: context, from: snapshot)
    try context.save()

    #expect(upserted?.id == entry.id)
    let entries = try context.fetch(FetchDescriptor<CounterEntry>())
    #expect(entries.count == 1)
    #expect(entries[0].amount == 12.5)
    #expect(entries[0].counter?.id == counter.id)
  }

  // MARK: - Apply semantics

  @Test func fullSnapshotRemovesCountersAndEntriesNotInPayload() throws {
    let (container, context) = makeStore()
    defer { _ = container }

    let keep = fixedCounter(name: "Keep", id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!)
    let drop = fixedCounter(name: "Drop", id: UUID(uuidString: "BBBBBBBB-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!)
    context.insert(keep)
    context.insert(drop)
    let keepEntry = CounterEntry(value: 1, timestamp: Date(timeIntervalSince1970: 10), counter: keep)
    keepEntry.id = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
    let dropEntry = CounterEntry(value: 2, timestamp: Date(timeIntervalSince1970: 20), counter: drop)
    dropEntry.id = UUID(uuidString: "22222222-2222-3333-4444-555555555555")!
    context.insert(keepEntry)
    context.insert(dropEntry)
    try context.save()
    let keepEntryID = keepEntry.id

    WatchSyncEngine.apply(
      WatchSyncEnvelope(
        payload: .fullSnapshot(
          counters: [CounterSnapshot(counter: keep)],
          entries: [EntrySnapshot(entry: keepEntry, counterID: keep.id)]
        ),
        sentAt: .now
      ),
      in: context
    )

    let counters = try context.fetch(FetchDescriptor<CustomCounter>())
    let entries = try context.fetch(FetchDescriptor<CounterEntry>())
    #expect(counters.map(\.name) == ["Keep"])
    #expect(entries.map(\.id) == [keepEntryID])
  }

  @Test func applyDeleteCounterRemovesIt() throws {
    let (container, context) = makeStore()
    defer { _ = container }

    let counterID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
    context.insert(fixedCounter(id: counterID))
    try context.save()

    WatchSyncEngine.apply(
      WatchSyncEnvelope(payload: .deleteCounter(counterID), sentAt: .now),
      in: context
    )

    #expect(try context.fetch(FetchDescriptor<CustomCounter>()).isEmpty)
  }

  @Test func applyResetAllClearsCounters() throws {
    let (container, context) = makeStore()
    defer { _ = container }

    context.insert(fixedCounter(name: "A", id: UUID()))
    context.insert(fixedCounter(name: "B", id: UUID()))
    try context.save()

    WatchSyncEngine.apply(
      WatchSyncEnvelope(payload: .resetAll, sentAt: .now),
      in: context
    )

    #expect(try context.fetch(FetchDescriptor<CustomCounter>()).isEmpty)
    #expect(try context.fetch(FetchDescriptor<CounterEntry>()).isEmpty)
  }
}
