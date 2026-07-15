import Foundation
import SwiftData
import Testing

@MainActor
struct QuickAddSessionStoreTests {
  private func makeContext() -> (ModelContext, CustomCounter) {
    let container = TestModelContainer.make()
    let context = ModelContext(container)
    let counter = CustomCounter(name: "Water")
    context.insert(counter)
    return (context, counter)
  }

  @Test func quickAddWithinBatchWindowAccumulatesIntoTheSameEntry() {
    let (context, counter) = makeContext()
    let store = QuickAddSessionStore()

    let first = store.addCounterEntryQuick(value: 10, counter: counter, in: context)
    let second = store.addCounterEntryQuick(value: 5, counter: counter, in: context)

    #expect(first.entryID == second.entryID)
    #expect(second.value == 15)
    #expect(counter.entries.count == 1)
  }

  @Test func quickAddAfterResetStartsANewEntry() {
    let (context, counter) = makeContext()
    let store = QuickAddSessionStore()

    let first = store.addCounterEntryQuick(value: 10, counter: counter, in: context)
    store.reset()
    let second = store.addCounterEntryQuick(value: 5, counter: counter, in: context)

    #expect(first.entryID != second.entryID)
    #expect(counter.entries.count == 2)
  }

  @Test func quickAddSessionsAreScopedPerCounter() {
    let (context, counterA) = makeContext()
    let counterB = CustomCounter(name: "Steps")
    context.insert(counterB)
    let store = QuickAddSessionStore()

    let entryA = store.addCounterEntryQuick(value: 10, counter: counterA, in: context)
    let entryB = store.addCounterEntryQuick(value: 20, counter: counterB, in: context)

    #expect(entryA.entryID != entryB.entryID)
    #expect(counterA.entries.count == 1)
    #expect(counterB.entries.count == 1)
  }

  @Test func quickAddSessionsAreIndependentPerStoreInstance() {
    let (context, counter) = makeContext()
    let storeA = QuickAddSessionStore()
    let storeB = QuickAddSessionStore()

    let first = storeA.addCounterEntryQuick(value: 10, counter: counter, in: context)
    let second = storeB.addCounterEntryQuick(value: 5, counter: counter, in: context)

    #expect(first.entryID != second.entryID)
    #expect(counter.entries.count == 2)
  }

  @Test func deletingTheBatchedEntryDirectlySelfHealsTheNextQuickAdd() {
    let (context, counter) = makeContext()
    let store = QuickAddSessionStore()

    let added = store.addCounterEntryQuick(value: 10, counter: counter, in: context)
    EntryActions.deleteCounterEntry(id: added.entryID, in: context)
    #expect(counter.entries.isEmpty)

    let next = store.addCounterEntryQuick(value: 5, counter: counter, in: context)
    #expect(next.entryID != added.entryID)
    #expect(next.value == 5)
  }
}
