import Foundation
import SwiftData

@Model
final class CalorieEntry {
  var id: UUID
  var value: Int
  var timestamp: Date

  init(value: Int, timestamp: Date = .now) {
    self.id = UUID()
    self.value = value
    self.timestamp = timestamp
  }
}
