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

    #expect(counter.entries.first?.value == 40)
  }

  @Test func deleteCounterEntryRemovesIt() {
    let (context, counter) = makeContext()
    let added = EntryActions.addCounterEntry(value: 10, counter: counter, in: context)

    EntryActions.deleteCounterEntry(id: added.entryID, in: context)

    #expect(counter.entries.isEmpty)
  }
}
