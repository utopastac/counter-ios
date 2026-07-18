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

/// Current schema: legacy calorie models are gone. `unit` / `sortOrder` live on
/// `CustomCounter` here. A separate V3 VersionedSchema that pointed at the *same* model
/// types was removed — SwiftData treats identical model graphs as duplicate checksums and
/// crashes container creation (even for a fresh store). Additive fields for existing
/// installs are handled by bumping `AppGroup.storeFilename` instead.
enum CounterSchemaV2: VersionedSchema {
  static let versionIdentifier = Schema.Version(2, 0, 0)

  static var models: [any PersistentModel.Type] {
    [CustomCounter.self, CounterEntry.self]
  }
}

/// Drives the one-time migration from the legacy single-counter calorie model into
/// `CustomCounter`/`CounterEntry`, and formally retires `CalorieEntry`/`AppSettings` from the
/// live schema once that data has moved.
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
