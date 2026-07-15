import Foundation

/// The save-gating rule shared by the counter creation and edit forms: a name is required
/// only when the form includes a name field, and an optional goal field may be left empty but
/// must parse to a positive integer if the user has typed something into it — typing "abc" or
/// "0" shouldn't silently save as "no goal", it should block save until cleared or corrected.
nonisolated enum CounterFormValidation {
  /// `name` should be `nil` when the form has no name field to validate (e.g. the quick-add
  /// preset editor reused for a fixed-name counter), and the trimmed candidate name otherwise.
  static func canSave(name: String?, goalText: String) -> Bool {
    if let name, name.trimmingCharacters(in: .whitespaces).isEmpty {
      return false
    }
    let trimmedGoal = goalText.trimmingCharacters(in: .whitespaces)
    if !trimmedGoal.isEmpty, AmountInput.parsePositiveInt(goalText) == nil {
      return false
    }
    return true
  }
}
