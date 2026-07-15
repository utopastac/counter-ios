import Foundation
import SwiftData
import Testing

@MainActor
struct CalorieMigrationTests {
  private func fetchCounters(in context: ModelContext) -> [CustomCounter] {
    (try? context.fetch(FetchDescriptor<CustomCounter>())) ?? []
  }

  private func fetchEntries(in context: ModelContext) -> [CounterEntry] {
    (try? context.fetch(FetchDescriptor<CounterEntry>())) ?? []
  }

  @Test func migrationIsANoOpWhenThereIsNoLegacyData() {
    let container = TestModelContainer.make()
    let context = ModelContext(container)

    CalorieMigration.migrateIfNeeded(in: context)

    #expect(fetchCounters(in: context).isEmpty)
  }

  @Test func migrationMovesLegacyCalorieEntriesIntoACaloriesCounter() {
    let container = TestModelContainer.make()
    let context = ModelContext(container)

    let legacyEntry = CalorieEntry(value: -40, timestamp: .now)
    context.insert(legacyEntry)

    CalorieMigration.migrateIfNeeded(in: context)

    let counters = fetchCounters(in: context)
    #expect(counters.count == 1)
    #expect(counters.first?.name == "Calories")

    let entries = fetchEntries(in: context)
    #expect(entries.count == 1)
    #expect(entries.first?.value == -40)

    let remainingLegacyEntries = (try? context.fetch(FetchDescriptor<CalorieEntry>())) ?? []
    #expect(remainingLegacyEntries.isEmpty)
  }

  @Test func migrationCarriesOverLegacySettingsOntoTheCaloriesCounter() {
    let container = TestModelContainer.make()
    let context = ModelContext(container)

    let settings = AppSettings(
      calorieButtonValues: [1, 2, 3, 4, 5, 6, 7, 8, 9],
      calorieSliderMax: 1500,
      calorieGoal: 1800,
      calorieResetPeriod: .weekly,
      calorieResetAnchorDay: 3,
      calorieGoalDirection: .countDown
    )
    context.insert(settings)

    CalorieMigration.migrateIfNeeded(in: context)

    let counter = fetchCounters(in: context).first
    #expect(counter?.effectiveGoal == 1800)
    #expect(counter?.resetPeriod == .weekly)
    #expect(counter?.effectiveResetAnchorDay == 3)
    #expect(counter?.effectiveSliderMax == 1500)

    let remainingSettings = (try? context.fetch(FetchDescriptor<AppSettings>())) ?? []
    #expect(remainingSettings.isEmpty)
  }

  @Test func migrationReusesAnExistingCaloriesCounterInsteadOfDuplicating() {
    let container = TestModelContainer.make()
    let context = ModelContext(container)

    let existing = CustomCounter(name: "Calories", goal: 2000)
    context.insert(existing)
    context.insert(CalorieEntry(value: -20, timestamp: .now))

    CalorieMigration.migrateIfNeeded(in: context)

    #expect(fetchCounters(in: context).count == 1)
  }
}
