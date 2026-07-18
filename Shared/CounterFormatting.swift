import Foundation

/// Display formatting for counter amounts. Storage is `Double` with up to two decimal places
/// (matching the keypad); whole numbers render without a trailing `.0`.
nonisolated enum CounterFormatting {
  static func amount(_ value: Double) -> String {
    if value.rounded() == value {
      return String(Int(value.rounded()))
    }

    let rounded = (value * 100).rounded() / 100
    var text = String(format: "%.2f", rounded)
    while text.hasSuffix("0") {
      text.removeLast()
    }
    if text.hasSuffix(".") {
      text.removeLast()
    }
    return text
  }

  static func amount(_ value: Double, unit: String) -> String {
    let trimmed = unit.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return amount(value) }
    return "\(amount(value)) \(trimmed)"
  }

  /// Header title with optional unit, e.g. `"Calories / kcal"`.
  static func titleWithUnit(name: String, unit: String) -> String {
    let trimmed = unit.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return name }
    return "\(name) / \(trimmed)"
  }

  static func editingText(for value: Double) -> String {
    amount(value)
  }
}
