import Foundation

/// Entry/goal/preset amounts are persisted as integer hundredths (two decimal places)
/// so SwiftData can keep `Int` columns and avoid a fragile Int→Double schema migration.
/// Domain and UI code use `Double`; convert at the storage boundary.
nonisolated enum CounterAmount {
  static let scale = 100

  static func storage(_ value: Double) -> Int {
    Int((value * Double(scale)).rounded())
  }

  static func display(_ storage: Int) -> Double {
    Double(storage) / Double(scale)
  }

  static func storage(_ values: [Double]) -> [Int] {
    values.map(storage)
  }

  static func display(_ values: [Int]) -> [Double] {
    values.map(display)
  }
}
