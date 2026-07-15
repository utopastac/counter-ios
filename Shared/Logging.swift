import Foundation
import os

/// Small `os.Logger` wrapper so best-effort SwiftData saves/fetches (`try?`) log their
/// failures to Console instead of disappearing silently. The app still treats these as
/// non-fatal — data loss here is rare and not worth crashing over — but a swallowed error
/// should be *visible*, not invisible.
enum AppLog {
  private static let subsystem = Bundle.main.bundleIdentifier ?? "com.becter.counter"

  static let data = Logger(subsystem: subsystem, category: "data")

  /// Runs `body`, logging (not throwing) if it fails. Mirrors `try?` at the call site
  /// while keeping the failure discoverable.
  @discardableResult
  static func attempt<T>(_ operation: String, _ body: () throws -> T) -> T? {
    do {
      return try body()
    } catch {
      data.error("\(operation) failed: \(error.localizedDescription, privacy: .public)")
      return nil
    }
  }
}
