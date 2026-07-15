import Foundation

/// The save-gating rule shared by the counter creation and edit forms: an empty name is
/// allowed (it becomes `CustomCounter.untitledName` on save), and an optional goal field may
/// be left empty but must parse to a positive integer if the user has typed something into it
/// — typing "abc" or "0" shouldn't silently save as "no goal", it should block save until
/// cleared or corrected.
nonisolated enum CounterFormValidation {
  /// `name` is accepted for API compatibility but is not validated — blank titles are allowed.
  static func canSave(name: String?, goalText: String) -> Bool {
    _ = name
    let trimmedGoal = goalText.trimmingCharacters(in: .whitespaces)
    if !trimmedGoal.isEmpty, AmountInput.parsePositiveInt(goalText) == nil {
      return false
    }
    return true
  }
}
