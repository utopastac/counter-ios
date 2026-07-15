import Foundation

/// Convenience accessors that combine `CounterPeriodCalculator` + `GoalProgressCalculator`
/// for a counter's *current* period. Every screen that shows a counter's live total or
/// goal progress (pager, list, widgets, watch) needs this exact pairing, so centralizing
/// it here means they can't quietly diverge (e.g. one site forgetting the goal direction,
/// or falling back to a different "no progress" string) the way the four call sites used to.
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

  /// Always renders a valid ring, even without a goal (see `GoalProgressCalculator.ringDisplay`).
  func currentRingDisplay(on date: Date = .now, calendar: Calendar = .current) -> GoalProgress {
    GoalProgressCalculator.ringDisplay(
      current: currentTotal(on: date, calendar: calendar),
      goal: effectiveGoal,
      direction: goalDirection
    )
  }
}
