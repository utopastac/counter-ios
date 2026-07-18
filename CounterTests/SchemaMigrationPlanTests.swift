import Foundation
import SwiftData
import Testing

/// Smoke-tests that the current schema opens cleanly with the migration plan attached —
/// matching `SharedModelContainer`. (File-backed V1→V2 upgrades are covered indirectly by
/// `CalorieMigrationTests`; constructing a true historical store against shared live model
/// types is unreliable once those types gain new fields.)
@MainActor
struct SchemaMigrationPlanTests {
  private func makeStoreURL() -> URL {
    URL.temporaryDirectory.appending(path: "SchemaMigrationPlanTests-\(UUID().uuidString).store")
  }

  @Test func openingAFreshV2StoreWithTheMigrationPlanSucceeds() throws {
    let storeURL = makeStoreURL()
    defer { try? FileManager.default.removeItem(at: storeURL) }

    let schema = Schema(versionedSchema: CounterSchemaV2.self)
    let container = try ModelContainer(
      for: schema,
      migrationPlan: CounterMigrationPlan.self,
      configurations: [ModelConfiguration(schema: schema, url: storeURL)]
    )
    let context = ModelContext(container)
    let counters = (try? context.fetch(FetchDescriptor<CustomCounter>())) ?? []
    #expect(counters.isEmpty)
  }
}
