import Foundation
import SwiftData
import Testing

/// Exercises `CounterMigrationPlan` end-to-end, not just the `CalorieMigration` logic it
/// wraps: opens a file-backed store shaped like `CounterSchemaV1` (legacy calorie models
/// present), seeds it with legacy data, closes it, then reopens the *same file* against
/// `CounterSchemaV2` with the migration plan attached — the same thing `SharedModelContainer`
/// does for a real upgrade. In-memory stores can't be used here since they don't persist
/// across separate `ModelContainer` instances, and persisting-then-reopening is the whole
/// point of what's being verified.
@MainActor
struct SchemaMigrationPlanTests {
  private func makeStoreURL() -> URL {
    URL.temporaryDirectory.appending(path: "SchemaMigrationPlanTests-\(UUID().uuidString).store")
  }

  private func fetchCounters(in context: ModelContext) -> [CustomCounter] {
    (try? context.fetch(FetchDescriptor<CustomCounter>())) ?? []
  }

  @Test func openingAV1StoreAgainstV2AutomaticallyMigratesLegacyCalorieData() throws {
    let storeURL = makeStoreURL()
    defer { try? FileManager.default.removeItem(at: storeURL) }

    do {
      let v1Schema = Schema(versionedSchema: CounterSchemaV1.self)
      let v1Container = try ModelContainer(
        for: v1Schema,
        configurations: [ModelConfiguration(schema: v1Schema, url: storeURL)]
      )
      let v1Context = ModelContext(v1Container)
      v1Context.insert(CalorieEntry(value: -40, timestamp: .now))
      try v1Context.save()
    }

    let v2Schema = Schema(versionedSchema: CounterSchemaV2.self)
    let v2Container = try ModelContainer(
      for: v2Schema,
      migrationPlan: CounterMigrationPlan.self,
      configurations: [ModelConfiguration(schema: v2Schema, url: storeURL)]
    )
    let v2Context = ModelContext(v2Container)

    let counters = fetchCounters(in: v2Context)
    #expect(counters.count == 1)
    #expect(counters.first?.name == "Calories")
    #expect(counters.first?.entries.count == 1)
  }

  @Test func openingAFreshV1StoreAgainstV2IsANoOpWhenThereIsNoLegacyData() throws {
    let storeURL = makeStoreURL()
    defer { try? FileManager.default.removeItem(at: storeURL) }

    do {
      let v1Schema = Schema(versionedSchema: CounterSchemaV1.self)
      _ = try ModelContainer(
        for: v1Schema,
        configurations: [ModelConfiguration(schema: v1Schema, url: storeURL)]
      )
    }

    let v2Schema = Schema(versionedSchema: CounterSchemaV2.self)
    let v2Container = try ModelContainer(
      for: v2Schema,
      migrationPlan: CounterMigrationPlan.self,
      configurations: [ModelConfiguration(schema: v2Schema, url: storeURL)]
    )
    let v2Context = ModelContext(v2Container)

    #expect(fetchCounters(in: v2Context).isEmpty)
  }
}
