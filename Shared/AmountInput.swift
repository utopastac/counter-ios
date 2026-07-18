import Foundation

/// Parsing/sanitizing rules for user-typed numeric text fields (amount entry, quick-add
/// preset editing, goal fields, entry-log editing, the numeric keypad). Centralized because
/// "what characters are allowed, what counts as a valid value" had silently drifted into
/// three slightly different hand-written answers across those call sites before this existed.
nonisolated enum AmountInput {
  /// Keeps only digits, capped at `maxLength` characters. For fields that only ever represent
  /// a positive count — amount entry, quick-add preset values, goal text.
  static func sanitizedDigits(_ raw: String, maxLength: Int) -> String {
    String(raw.filter(\.isWholeNumber).prefix(maxLength))
  }

  /// Like `sanitizedDigits`, but keeps a single leading `-` and at most one `.` with up to
  /// two fractional digits. Used by entry-log editing, where a past entry may legitimately
  /// need correcting to a negative or fractional value.
  static func sanitizedSignedDecimal(_ raw: String, maxLength: Int) -> String {
    var result = ""
    var hasDecimal = false
    var fractionalDigits = 0

    for (index, character) in raw.enumerated() {
      if character.isWholeNumber {
        if hasDecimal {
          guard fractionalDigits < 2 else { continue }
          fractionalDigits += 1
        }
        result.append(character)
      } else if character == "-", index == 0, result.isEmpty {
        result.append(character)
      } else if character == ".", !hasDecimal {
        hasDecimal = true
        if result.isEmpty || result == "-" {
          result.append("0")
        }
        result.append(character)
      }
    }

    return String(result.prefix(maxLength))
  }

  /// Parses text as a strictly positive amount. Accepts optional two-digit decimals
  /// (`"12."`, `"12.5"`, `"12.50"`). `0`, negative numbers, and unparseable text are `nil`.
  static func parsePositiveAmount(_ text: String) -> Double? {
    guard let decimal = parseDecimal(text), decimal > 0 else { return nil }
    return NSDecimalNumber(decimal: decimal).doubleValue
  }

  /// Parses text as any finite amount, including negatives and zero (entry-log edits).
  static func parseSignedAmount(_ text: String) -> Double? {
    guard let decimal = parseDecimal(text) else { return nil }
    return NSDecimalNumber(decimal: decimal).doubleValue
  }

  /// Appends `digit` to `text` respecting `maxDigits` on the integer part and at most two
  /// digits after a decimal separator. Replaces a lone leading `"0"` (with no decimal) instead
  /// of producing `"05"`. Used by the numeric keypad.
  static func appendingDigit(_ digit: String, to text: String, maxDigits: Int) -> String {
    if let separatorIndex = text.firstIndex(of: ".") {
      let decimalDigits = text[text.index(after: separatorIndex)...]
      guard decimalDigits.count < 2 else { return text }
      return text + digit
    }

    guard text.count < maxDigits else { return text }
    return text == "0" ? digit : text + digit
  }

  /// Inserts a decimal separator if one is not already present. An empty field becomes `"0."`.
  static func appendingDecimalSeparator(to text: String) -> String {
    guard !text.contains(".") else { return text }
    return text.isEmpty ? "0." : text + "."
  }

  private static func parseDecimal(_ text: String) -> Decimal? {
    let trimmed = text.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return nil }

    let normalized = trimmed.hasSuffix(".") ? String(trimmed.dropLast()) : trimmed
    return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
  }
}
