import Foundation
import SwiftData

/// The schema as it has always shipped: `CustomCounter`/`CounterEntry` alongside the legacy
/// single-counter calorie models (`CalorieEntry`, `AppSettings`). Every install that has ever
/// opened this app's store matches this version — there was no earlier one.
enum CounterSchemaV1: VersionedSchema {
  static let versionIdentifier = Schema.Version(1, 0, 0)

  static var models: [any PersistentModel.Type] {
    [CalorieEntry.self, CustomCounter.self, CounterEntry.self, AppSettings.self]
  }
}

/// The current schema: legacy calorie models are gone. `CalorieMigration` (run once, in
/// `CounterMigrationPlan`'s custom stage) moves any of their data into a `CustomCounter`
/// before the store is upgraded to this version.
enum CounterSchemaV2: VersionedSchema {
  static let versionIdentifier = Schema.Version(2, 0, 0)

  static var models: [any PersistentModel.Type] {
    [CustomCounter.self, CounterEntry.self]
  }
}

/// Drives the one-time migration from the legacy single-counter calorie model into
/// `CustomCounter`/`CounterEntry`, and formally retires `CalorieEntry`/`AppSettings` from the
/// live schema once that data has moved.
///
/// This replaces an earlier design where `CalorieMigration.migrateIfNeeded` was called by hand
/// from `SampleDataSeeder` on every app launch, re-checking "is there legacy data?" every time
/// via a guard clause. `SchemaMigrationPlan` is SwiftData's own mechanism for exactly this kind
/// of migration (moving data between distinct model types, not just adding/removing a
/// property) — it runs the stage automatically, exactly once, when a V1-shaped store is opened
/// against a V2 schema, instead of the app re-deriving "should I check for legacy data?" itself
/// on the hot path of every launch.
enum CounterMigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] {
    [CounterSchemaV1.self, CounterSchemaV2.self]
  }

  static var stages: [MigrationStage] {
    [migrateV1toV2]
  }

  /// `willMigrate` runs against a `ModelContext` still bound to V1's schema — the last point at
  /// which `CalorieEntry`/`AppSettings` are fetchable — so this is where `CalorieMigration`'s
  /// data move has to happen. By the time `didMigrate` would run, V2's schema is already
  /// active and those types are gone from it.
  private static let migrateV1toV2 = MigrationStage.custom(
    fromVersion: CounterSchemaV1.self,
    toVersion: CounterSchemaV2.self,
    willMigrate: { context in
      CalorieMigration.migrateIfNeeded(in: context)
    },
    didMigrate: nil
  )
}
