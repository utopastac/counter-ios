import Foundation

/// Audio, photo, sketch, and place-map files for journal entries. Paths stored on `CounterEntry`
/// are relative to this directory inside the App Group so iPhone and Watch see the same files.
enum JournalMediaStore {
  private static let rootFolder = "JournalMedia"

  static func save(data: Data, entryID: UUID, fileExtension: String) -> String {
    let relative = "entries/\(entryID.uuidString).\(fileExtension)"
    guard let url = fileURL(relativePath: relative) else { return "" }
    do {
      try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      try data.write(to: url, options: .atomic)
      return relative
    } catch {
      return ""
    }
  }

  static func fileURL(relativePath: String) -> URL? {
    guard !relativePath.isEmpty else { return nil }
    return rootURL().appendingPathComponent(relativePath)
  }

  static func delete(relativePath: String) {
    guard let url = fileURL(relativePath: relativePath) else { return }
    try? FileManager.default.removeItem(at: url)
  }

  /// Moves a file aside so an entry-log undo can put it back. Returns the trashed relative path.
  static func trash(relativePath: String) -> String {
    guard let source = fileURL(relativePath: relativePath) else { return "" }
    let ext = source.pathExtension.isEmpty ? "dat" : source.pathExtension
    let trashed = "trash/\(UUID().uuidString).\(ext)"
    guard let destination = fileURL(relativePath: trashed) else { return "" }
    do {
      try FileManager.default.createDirectory(
        at: destination.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      try FileManager.default.moveItem(at: source, to: destination)
      return trashed
    } catch {
      return ""
    }
  }

  /// Moves a trashed file back to a stable entry path. Returns that relative path.
  static func restore(trashedRelativePath: String, entryID: UUID) -> String {
    guard let source = fileURL(relativePath: trashedRelativePath) else { return "" }
    let ext = source.pathExtension.isEmpty ? "dat" : source.pathExtension
    let restored = "entries/\(entryID.uuidString).\(ext)"
    guard let destination = fileURL(relativePath: restored) else { return "" }
    do {
      try FileManager.default.createDirectory(
        at: destination.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      try FileManager.default.moveItem(at: source, to: destination)
      return restored
    } catch {
      return ""
    }
  }

  static func purge(relativePath: String) {
    delete(relativePath: relativePath)
  }

  static func deleteFiles(for counter: CustomCounter) {
    for entry in counter.entries {
      delete(relativePath: entry.mediaRelativePath)
    }
  }

  static func removeAll() {
    try? FileManager.default.removeItem(at: rootURL())
  }

  private static func rootURL() -> URL {
    let base = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: AppGroup.identifier
    ) ?? FileManager.default.temporaryDirectory
    return base.appendingPathComponent(rootFolder, isDirectory: true)
  }
}
