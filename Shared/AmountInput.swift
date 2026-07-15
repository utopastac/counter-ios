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

  /// Like `sanitizedDigits`, but keeps a single leading `-`. Used only by entry-log editing,
  /// where a past entry may legitimately need correcting to a negative value — quick-add,
  /// goal, and amount-entry fields never allow that.
  static func sanitizedSignedDigits(_ raw: String, maxLength: Int) -> String {
    var result = ""
    for (index, character) in raw.enumerated() {
      if character.isWholeNumber {
        result.append(character)
      } else if character == "-", index == 0 {
        result.append(character)
      }
    }
    return String(result.prefix(maxLength))
  }

  /// Parses text as a strictly positive integer. `0`, negative numbers, and unparseable text
  /// are all `nil` — used anywhere only a positive count makes sense (amount entry, quick-add
  /// presets, goal fields).
  static func parsePositiveInt(_ text: String) -> Int? {
    guard let value = Int(text.trimmingCharacters(in: .whitespaces)), value > 0 else {
      return nil
    }
    return value
  }

  /// Appends `digit` to `text` respecting `maxDigits`, replacing a lone leading `"0"` instead
  /// of producing `"05"`. Used by the numeric keypad.
  static func appendingDigit(_ digit: String, to text: String, maxDigits: Int) -> String {
    guard text.count < maxDigits else { return text }
    return text == "0" ? digit : text + digit
  }
}
