import Foundation

/// Convenience accessors that combine `CounterPeriodCalculator` + `GoalProgressCalculator`
/// for a counter's *current* period. Every screen that shows a counter's live total or
/// goal progress (pager, list, widgets, watch) needs this exact pairing, so centralizing
/// it here means they can't quietly diverge (e.g. one site forgetting the goal direction,
/// or falling back to a different "no progress" string) the way the four call sites used to.
///
/// Explicitly `@MainActor` because it reads `self.entries`/`self.effectiveGoal` on a
/// SwiftData `@Model`. `@Model` types opt out of the module's default `MainActor` actor
/// isolation (unlike plain enums/structs, which inherit it), so this annotation is load-bearing,
/// not decorative — omitting it makes this `nonisolated`, which fails to compile against
/// `ModelContext`-bound state that the rest of the app only ever touches from the main actor.
/// The math itself (`CounterPeriodCalculator`, `GoalProgressCalculator`) is `nonisolated`;
/// only the act of reading the model's stored properties requires this.
@MainActor
extension CustomCounter {
  func currentTotal(on date: Date = .now, calendar: Calendar = .current) -> Int {
    CounterPeriodCalculator.total(from: entries, for: self, on: date, calendar: calendar)
  }

  /// `nil` when the counter has no active goal — callers decide how to present that case.
  func currentProgress(on date: Date = .now, calendar: Calendar = .current) -> GoalProgress? {
    GoalProgressCalculator.progress(
      current: currentTotal(on: date, calendar: calendar),
      goal: effectiveGoal,
      direction: goalDirection
    )
  }
}
