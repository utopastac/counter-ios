import Foundation

/// Rounds amounts to two decimal places at the persistence boundary.
nonisolated enum CounterAmount {
  static let scale = 100

  static func rounded(_ value: Double) -> Double {
    (value * Double(scale)).rounded() / Double(scale)
  }

  static func rounded(_ values: [Double]) -> [Double] {
    values.map(rounded)
  }
}
