import Foundation
import SwiftData

@Model
final class CounterEntry {
  var id: UUID
  var value: Int
  var timestamp: Date
  var counter: CustomCounter?

  init(value: Int, timestamp: Date = .now, counter: CustomCounter? = nil) {
    self.id = UUID()
    self.value = value
    self.timestamp = timestamp
    self.counter = counter
  }
}
