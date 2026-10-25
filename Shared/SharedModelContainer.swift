import Foundation
import SwiftData

enum SharedModelContainer {
  static let schema = Schema([
    CustomCounter.self,
    CounterEntry.self
  ])

  private static var usesInMemoryStore: Bool {
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"
      || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
      // Screenshot / UI tests seed a disposable store; don't touch the App Group file.
      || ProcessInfo.processInfo.arguments.contains("-UITesting")
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

  private static let legacyStoreFilename = "Counter-v7.store"
  private static let legacyImportedMarker = "Counter-v7.imported"

  private static func makePersistentContainer() -> ModelContainer {
    let storeURL = resolveStoreURL()
    importLegacyStoreIfNeeded(into: storeURL)
    let configuration = ModelConfiguration(schema: schema, url: storeURL)

    do {
      let container = try ModelContainer(for: schema, configurations: [configuration])
      markLegacyStoreImported(near: storeURL)
      return container
    } catch {
      AppLog.data.error(
        "ModelContainer open failed; resetting store at \(storeURL.path, privacy: .public): \(error.localizedDescription, privacy: .public)"
      )
      removeStore(at: storeURL)
      do {
        return try ModelContainer(for: schema, configurations: [configuration])
      } catch {
        fatalError("Failed to create shared ModelContainer: \(error)")
      }
    }
  }

  /// The journal update opened `Counter-v8.store` and left the previous file untouched.
  /// Copy it over the new store once, before the container opens, so existing counters come back.
  private static func importLegacyStoreIfNeeded(into destination: URL) {
    let fileManager = FileManager.default
    let directory = destination.deletingLastPathComponent()
    let marker = directory.appendingPathComponent(legacyImportedMarker)
    let legacy = directory.appendingPathComponent(legacyStoreFilename)
    guard !fileManager.fileExists(atPath: marker.path),
          fileManager.fileExists(atPath: legacy.path)
    else { return }

    removeStore(at: destination)
    copyStore(from: legacy, to: destination)
  }

  private static func markLegacyStoreImported(near storeURL: URL) {
    let directory = storeURL.deletingLastPathComponent()
    let legacy = directory.appendingPathComponent(legacyStoreFilename)
    guard FileManager.default.fileExists(atPath: legacy.path) else { return }
    let marker = directory.appendingPathComponent(legacyImportedMarker)
    try? Data("imported".utf8).write(to: marker)
  }

  private static func copyStore(from source: URL, to destination: URL) {
    let fileManager = FileManager.default
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: source.path, isDirectory: &isDirectory) else { return }

    if isDirectory.boolValue {
      try? fileManager.copyItem(at: source, to: destination)
      return
    }

    for suffix in ["", "-wal", "-shm"] {
      let from = source.path + suffix
      guard fileManager.fileExists(atPath: from) else { continue }
      try? fileManager.copyItem(atPath: from, toPath: destination.path + suffix)
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
