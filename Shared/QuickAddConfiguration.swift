import Foundation

nonisolated enum QuickAddConfiguration {
  static let buttonCount = 10
  static let presetCount = buttonCount - 1

  static let defaultCaloriePresets: [Int] = [5, 10, 25, 50, 100, 200, 500, 1000, 50]
  static let defaultCounterPresets: [Int] = [1, 2, 5, 10, 20, 50, 100, 25, 75]
  static let defaultFilledCaloriePresets: [Int] = [5, 10, 25, 50, 50, 100, 200, 500, 1000]
  static let defaultFilledCounterPresets: [Int] = [1, 2, 5, 10, 20, 25, 50, 75, 100]

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
