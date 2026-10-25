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

  @Test func noteEntryCountsTowardTheCapAndThenStops() {
    let container = TestModelContainer.make()
    let context = ModelContext(container)
    let counter = CustomCounter(name: "Note", goal: 1, kind: .note)
    context.insert(counter)

    let first = EntryActions.addNoteEntry(text: "Morning", counter: counter, in: context)
    let second = EntryActions.addNoteEntry(text: "Again", counter: counter, in: context)

    #expect(first != nil)
    #expect(second == nil)
    #expect(counter.currentTotal() == 1)
    #expect(counter.entries.first?.noteText == "Morning")
    #expect(counter.entries.first?.previewText == "Morning")
  }

  @Test func placeEntryStoresCoordinates() {
    let container = TestModelContainer.make()
    let context = ModelContext(container)
    let counter = CustomCounter(name: "Places", goal: 3, kind: .place)
    context.insert(counter)

    _ = EntryActions.addPlaceEntry(latitude: 51.5, longitude: -0.12, counter: counter, in: context)

    #expect(counter.entries.first?.latitude == 51.5)
    #expect(counter.entries.first?.previewText == "51.5000, -0.1200")
    #expect(counter.acceptsAnotherEntry())
  }

  @Test func bookPreviewShowsTheTitleLine() {
    let container = TestModelContainer.make()
    let context = ModelContext(container)
    let counter = CustomCounter(name: "Books", goal: 3, kind: .book)
    context.insert(counter)

    let entry = CounterEntry(value: 1, counter: counter)
    entry.noteText = "Beloved\nToni Morrison · 1987"
    context.insert(entry)

    #expect(entry.previewText == "Beloved")
  }

  @Test func mediaEntryStoresTheFileAndNoteThenStopsAtTheCap() throws {
    let container = TestModelContainer.make()
    let context = ModelContext(container)
    let counter = CustomCounter(name: "Books", goal: 1, kind: .book)
    context.insert(counter)

    let payload = Data("photo".utf8)
    let added = EntryActions.addMediaEntry(
      data: payload,
      fileExtension: "jpg",
      counter: counter,
      noteText: "Beloved\nToni Morrison · 1987",
      in: context
    )
    let savedPath = counter.entries.first?.mediaRelativePath ?? ""
    defer { JournalMediaStore.delete(relativePath: savedPath) }

    let entry = try #require(counter.entries.first)
    #expect(added?.entryID == entry.id)
    #expect(entry.noteText == "Beloved\nToni Morrison · 1987")
    #expect(entry.previewText == "Beloved")
    let fileURL = try #require(JournalMediaStore.fileURL(relativePath: entry.mediaRelativePath))
    #expect(try Data(contentsOf: fileURL) == payload)

    let second = EntryActions.addMediaEntry(
      data: payload,
      fileExtension: "jpg",
      counter: counter,
      in: context
    )
    #expect(second == nil)
    #expect(counter.currentTotal() == 1)
    #expect(counter.entries.count == 1)
  }
}
