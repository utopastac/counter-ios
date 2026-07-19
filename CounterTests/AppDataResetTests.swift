import Foundation
import SwiftData
import Testing

@MainActor
struct AppDataResetTests {
  @Test func resetAllRestoresThreeDefaultCountersWithoutCrashing() throws {
    let container = TestModelContainer.make()
    let context = container.mainContext

    let existing = CustomCounter(name: "Custom", goal: 10)
    context.insert(existing)
    context.insert(CounterEntry(value: 3, counter: existing))
    try context.save()

    UserDefaults.standard.set(true, forKey: AppDataReset.suppressSampleSeedingKey)

    AppDataReset.resetAll(in: context)

    let counters = try context.fetch(
      FetchDescriptor<CustomCounter>(sortBy: [SortDescriptor(\.sortOrder)])
    )
    #expect(counters.map(\.name) == ["Calories", "Protein", "Money"])
    #expect(UserDefaults.standard.bool(forKey: AppDataReset.suppressSampleSeedingKey) == false)

    let entries = try context.fetch(FetchDescriptor<CounterEntry>())
    #expect(entries.isEmpty)
    for counter in counters {
      #expect(counter.currentTotal() == 0)
    }
  }
}
