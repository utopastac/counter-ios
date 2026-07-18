import Foundation
import SwiftData

enum SharedModelContainer {
  static let schema = Schema(versionedSchema: CounterSchemaV2.self)

  private static var usesInMemoryStore: Bool {
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"
      || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
  }

  static let shared: ModelContainer = {
    if usesInMemoryStore {
      return makeInMemoryContainer()
    }
    return makePersistentContainer()
  }()

  private static func makeInMemoryContainer() -> ModelContainer {
    do {
      let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
      return try ModelContainer(for: schema, configurations: [configuration])
    } catch {
      fatalError("Failed to create in-memory ModelContainer: \(error)")
    }
  }

  private static func makePersistentContainer() -> ModelContainer {
    let storeURL = resolveStoreURL()
    let configuration = ModelConfiguration(schema: schema, url: storeURL)

    do {
      return try ModelContainer(
        for: schema,
        migrationPlan: CounterMigrationPlan.self,
        configurations: [configuration]
      )
    } catch {
      AppLog.data.error(
        "ModelContainer open failed; resetting store at \(storeURL.path, privacy: .public): \(error.localizedDescription, privacy: .public)"
      )
      removeStore(at: storeURL)
      do {
        return try ModelContainer(
          for: schema,
          migrationPlan: CounterMigrationPlan.self,
          configurations: [configuration]
        )
      } catch {
        fatalError("Failed to create shared ModelContainer: \(error)")
      }
    }
  }

  private static func resolveStoreURL() -> URL {
    if let groupURL = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: AppGroup.identifier
    ) {
      return groupURL.appendingPathComponent(AppGroup.storeFilename)
    }
    return URL.documentsDirectory.appending(path: AppGroup.storeFilename)
  }

  private static func removeStore(at url: URL) {
    let fileManager = FileManager.default
    let relatedPaths = [
      url.path,
      url.path + "-wal",
      url.path + "-shm"
    ]

    for path in relatedPaths {
      try? fileManager.removeItem(atPath: path)
    }
  }
}
