import Foundation
import SwiftData

@Model
final class CounterEntry {
  var id: UUID
  var value: Double
  var timestamp: Date
  var counter: CustomCounter?

  init(value: Double, timestamp: Date = .now, counter: CustomCounter? = nil) {
    self.id = UUID()
    self.value = CounterAmount.rounded(value)
    self.timestamp = timestamp
    self.counter = counter
  }

  var amount: Double {
    get { value }
    set { value = CounterAmount.rounded(newValue) }
  }
}
