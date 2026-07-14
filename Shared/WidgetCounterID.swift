import Foundation

enum WidgetCounterID: Sendable {
  nonisolated static let calories = "calories"

  nonisolated static func isCalories(_ id: String) -> Bool {
    id == calories
  }
}
