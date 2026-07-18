import Foundation

nonisolated enum QuickAddConfiguration {
  static let buttonCount = 10
  static let presetCount = buttonCount - 1

  static let defaultCaloriePresets: [Double] = [5, 10, 25, 50, 100, 200, 500, 1000, 50]
  static let defaultCounterPresets: [Double] = [1, 2, 5, 10, 20, 50, 100, 25, 75]

  static func normalizedPresets(_ values: [Double]) -> [Double] {
    Array(values.sorted().prefix(presetCount))
  }

  static func filledPresets(from stored: [Double], defaults: [Double]) -> [Double] {
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

  /// Which built-in preset set a counter should default to, based on its name. Only
  /// "Calories" gets calorie-appropriate presets; every other counter gets the generic set.
  /// Prefer `CounterTemplate` when creating new counters — this remains for counters that
  /// were renamed to "Calories" or migrated from the legacy calorie model.
  static func defaultPresets(forCounterNamed name: String) -> [Double] {
    name.lowercased() == "calories" ? defaultCaloriePresets : defaultCounterPresets
  }

  /// Applies a single preset-field edit: replaces `old` in place if it's one of the
  /// user-stored `values`, appends `new` if there's room and `old` wasn't stored (i.e. the
  /// edited slot was only visible via `filledPresets`' fallback), then re-normalizes.
  /// Non-positive input is silently ignored, matching every other preset/amount field.
  static func replacingPreset(_ old: Double, with new: Double, in values: [Double]) -> [Double] {
    guard new > 0 else { return values }

    var updated = values
    if let index = updated.firstIndex(of: old) {
      updated[index] = new
    } else if updated.count < presetCount {
      updated.append(new)
    }

    return normalizedPresets(updated)
  }
}
