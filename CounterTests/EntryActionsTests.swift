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
    EntryActions.clearAllQuickAddSessions()
    return (context, counter)
  }

  @Test func addCounterEntryInsertsANewEntryWithTheGivenValue() {
    let (context, counter) = makeContext()

    let added = EntryActions.addCounterEntry(value: 25, counter: counter, in: context)

    #expect(added.value == 25)
    #expect(counter.entries.count == 1)
  }

  @Test func quickAddWithinBatchWindowAccumulatesIntoTheSameEntry() {
    let (context, counter) = makeContext()

    let first = EntryActions.addCounterEntryQuick(value: 10, counter: counter, in: context)
    let second = EntryActions.addCounterEntryQuick(value: 5, counter: counter, in: context)

    #expect(first.entryID == second.entryID)
    #expect(second.value == 15)
    #expect(counter.entries.count == 1)
  }

  @Test func quickAddAfterClearingSessionsStartsANewEntry() {
    let (context, counter) = makeContext()

    let first = EntryActions.addCounterEntryQuick(value: 10, counter: counter, in: context)
    EntryActions.clearAllQuickAddSessions()
    let second = EntryActions.addCounterEntryQuick(value: 5, counter: counter, in: context)

    #expect(first.entryID != second.entryID)
    #expect(counter.entries.count == 2)
  }

  @Test func quickAddSessionsAreScopedPerCounter() {
    let (context, counterA) = makeContext()
    let counterB = CustomCounter(name: "Steps")
    context.insert(counterB)

    let entryA = EntryActions.addCounterEntryQuick(value: 10, counter: counterA, in: context)
    let entryB = EntryActions.addCounterEntryQuick(value: 20, counter: counterB, in: context)

    #expect(entryA.entryID != entryB.entryID)
    #expect(counterA.entries.count == 1)
    #expect(counterB.entries.count == 1)
  }

  @Test func updateCounterEntryChangesItsValue() {
    let (context, counter) = makeContext()
    let added = EntryActions.addCounterEntry(value: 10, counter: counter, in: context)

    EntryActions.updateCounterEntry(id: added.entryID, value: 40, in: context)

    #expect(counter.entries.first?.value == 40)
  }

  @Test func deleteCounterEntryRemovesItAndClearsItsQuickAddSession() {
    let (context, counter) = makeContext()
    let added = EntryActions.addCounterEntryQuick(value: 10, counter: counter, in: context)

    EntryActions.deleteCounterEntry(id: added.entryID, in: context)
    #expect(counter.entries.isEmpty)

    // Since the session was cleared, the next quick add starts a fresh entry.
    let next = EntryActions.addCounterEntryQuick(value: 5, counter: counter, in: context)
    #expect(next.entryID != added.entryID)
    #expect(next.value == 5)
  }
}
