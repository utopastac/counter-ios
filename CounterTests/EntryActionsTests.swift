import Foundation
import SwiftData
import Testing

@MainActor
struct EntryActionsTests {
  private func makeContext() -> (ModelContext, CustomCounter) {
    let container = TestModelContainer.make()
    let context = ModelContext(container)
    let counter = CustomCounter(name: "Water")
    context.insert(counter)
    return (context, counter)
  }

  @Test func addCounterEntryInsertsANewEntryWithTheGivenValue() {
    let (context, counter) = makeContext()

    let added = EntryActions.addCounterEntry(value: 25, counter: counter, in: context)

    #expect(added.value == 25)
    #expect(counter.entries.count == 1)
  }

  @Test func updateCounterEntryChangesItsValue() {
    let (context, counter) = makeContext()
    let added = EntryActions.addCounterEntry(value: 10, counter: counter, in: context)

    EntryActions.updateCounterEntry(id: added.entryID, value: 40, in: context)

    #expect(counter.entries.first?.amount == 40)
  }

  @Test func deleteCounterEntryRemovesIt() {
    let (context, counter) = makeContext()
    let added = EntryActions.addCounterEntry(value: 10, counter: counter, in: context)

    EntryActions.deleteCounterEntry(id: added.entryID, in: context)

    #expect(counter.entries.isEmpty)
  }

  @Test func restoreCounterEntryReinsertsWithTheOriginalIdentity() {
    let (context, counter) = makeContext()
    let added = EntryActions.addCounterEntry(value: 10, counter: counter, in: context)
    let originalID = added.entryID
    let timestamp = counter.entries.first!.timestamp

    EntryActions.deleteCounterEntry(id: originalID, in: context)
    #expect(counter.entries.isEmpty)

    let restored = EntryActions.restoreCounterEntry(
      id: originalID,
      value: 10,
      timestamp: timestamp,
      counter: counter,
      in: context
    )

    #expect(restored.entryID == originalID)
    #expect(counter.entries.count == 1)
    #expect(counter.entries.first?.amount == 10)
    #expect(counter.entries.first?.timestamp == timestamp)
  }
}
