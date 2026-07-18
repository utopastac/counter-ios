import Foundation
import SwiftData

@Model
final class CounterEntry {
  var id: UUID
  /// Amount stored as hundredths (`CounterAmount`).
  var value: Int
  var timestamp: Date
  var counter: CustomCounter?

  init(value: Double, timestamp: Date = .now, counter: CustomCounter? = nil) {
    self.id = UUID()
    self.value = CounterAmount.storage(value)
    self.timestamp = timestamp
    self.counter = counter
  }

  /// Inserts a pre-scaled storage int (whole numbers during legacy migration, hundredths after).
  init(storageValue: Int, timestamp: Date = .now, counter: CustomCounter? = nil) {
    self.id = UUID()
    self.value = storageValue
    self.timestamp = timestamp
    self.counter = counter
  }

  var amount: Double {
    get { CounterAmount.display(value) }
    set { value = CounterAmount.storage(newValue) }
  }
}
