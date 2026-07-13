import Foundation

enum QuickAddConfiguration {
  static let buttonCount = 8
  static let presetCount = buttonCount - 1

  static let defaultCaloriePresets: [Int] = [10, 20, 50, 100, 200, 500, 1000]
  static let defaultCounterPresets: [Int] = [1, 2, 5, 10, 20, 50, 100]

  static func normalizedPresets(_ values: [Int]) -> [Int] {
    Array(values.sorted().prefix(presetCount))
  }

  static func filledPresets(from stored: [Int], defaults: [Int]) -> [Int] {
    var result = normalizedPresets(stored)
    guard result.count < presetCount else { return result }

    for value in defaults.sorted() {
      guard result.count < presetCount else { break }
      if !result.contains(value) {
        result.append(value)
      }
    }

    return result.sorted()
  }
}
