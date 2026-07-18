import Foundation

nonisolated enum GoalDirection: String, Codable, CaseIterable, Identifiable {
  case countUp
  case countDown

  var id: String { rawValue }

  var label: String {
    switch self {
    case .countUp: "Count up"
    case .countDown: "Count down"
    }
  }
}

nonisolated struct GoalProgress {
  let current: Double
  let goal: Double
  let direction: GoalDirection

  var delta: Double {
    goal - current
  }

  var fractionComplete: Double {
    guard goal > 0 else { return 0 }
    return current / goal
  }

  var ringFraction: Double {
    guard goal > 0 else { return 0 }
    switch direction {
    case .countUp:
      return min(max(current / goal, 0), 1)
    case .countDown:
      return min(max(delta / goal, 0), 1)
    }
  }

  /// Continuous, *unwrapped* extra-lap progress once a count-up target is exceeded (e.g. 2.5
  /// once `current` reaches 350% of `goal`) — wound clockwise on top of the completed base
  /// ring, mirroring how Apple's Activity rings keep wrapping around themselves instead of
  /// stopping at one extra loop.
  ///
  /// Only meaningful for `.countUp`: exceeding a target is worth celebrating with an extra
  /// lap. Exceeding a `.countDown` budget isn't an achievement, so it renders as an empty ring
  /// instead (see `rendersEmptyRing`) rather than looping forward.
  ///
  /// This deliberately does *not* wrap into `[0, 1]` — the ring shape does that internally when
  /// drawing. Wrapping here would mean the value resets from ~1 back to ~0 every time `current`
  /// crosses a lap boundary (e.g. 200%), and since that's the value SwiftUI animates between,
  /// the ring would visibly unwind backwards across almost a whole lap instead of continuing
  /// forward. Keeping it monotonic means every increase in `current` is a small forward step.
  var overflowLoopProgress: Double {
    guard direction == .countUp, fractionComplete > 1 else { return 0 }
    return fractionComplete - 1
  }

  var isOverGoal: Bool {
    current > goal
  }

  var amountOverTarget: Double {
    current - goal
  }

  /// True once progress has dropped below 0% (e.g. a negative logged total). Not a state
  /// today's UI can produce — there's no decrement, and entries require positive values —
  /// but the ring still renders empty rather than snapping to a misleading full circle
  /// (`ringFraction`'s countDown formula would otherwise read a negative `current` as "over
  /// 100% of budget remaining").
  var isUnderZero: Bool {
    fractionComplete < 0
  }

  /// True when the ring has nothing meaningful to draw and should just render empty: always
  /// once `current` is negative, and — unlike `.countUp` exceeding its target — also once a
  /// `.countDown` budget goes over, since blowing a limit isn't an extra lap to celebrate.
  var rendersEmptyRing: Bool {
    isUnderZero || (direction == .countDown && isOverGoal)
  }

  var percentComplete: Int {
    Int((fractionComplete * 100).rounded())
  }

  private func formatted(_ value: Double) -> String {
    CounterFormatting.amount(value)
  }

  /// Amount only — the pager hero renders the unit beside this at half size.
  var heroValue: String {
    CounterFormatting.amount(current)
  }

  /// A single-line hero string with goal context folded in (e.g. `"70/150"`) for count-up
  /// goals, or just `heroValue` for count-down ones (already "remaining", which needs no
  /// extra context). For screens with no room for a separate caption line — currently just
  /// the Watch detail view, which has no `heroCaption`/`heroSubtitle` line under its hero
  /// number the way the iPhone pager and list do.
  var compactHeroValue: String {
    switch direction {
    case .countUp:
      return "\(CounterFormatting.amount(current))/\(CounterFormatting.amount(goal))"
    case .countDown:
      return heroValue
    }
  }

  var heroCaption: String {
    switch direction {
    case .countUp:
      return "of \(formatted(goal))"
    case .countDown:
      return "remaining"
    }
  }

  var heroSubtitle: String {
    if isOverGoal {
      return "\(formatted(amountOverTarget)) over target"
    }
    switch direction {
    case .countUp:
      return "\(formatted(delta)) to go"
    case .countDown:
      return "\(formatted(delta)) remaining"
    }
  }

  var statsSummaryValue: String {
    if isOverGoal {
      return formatted(amountOverTarget)
    }
    return formatted(delta)
  }

  var statsSummaryLabel: String {
    if isOverGoal {
      return "Over target"
    }
    switch direction {
    case .countUp:
      return "To go"
    case .countDown:
      return "Remaining"
    }
  }

  var progressLabel: String {
    switch direction {
    case .countUp:
      return isOverGoal ? "Over target" : "Progress"
    case .countDown:
      return "Budget used"
    }
  }

  var detailLabel: String {
    if isOverGoal {
      return "\(formatted(amountOverTarget)) over target"
    }
    switch direction {
    case .countUp:
      return "\(CounterFormatting.amount(current)) / \(formatted(goal))"
    case .countDown:
      return "\(formatted(delta)) remaining"
    }
  }
}

nonisolated enum GoalProgressCalculator {
  static func progress(
    current: Double,
    goal: Double?,
    direction: GoalDirection
  ) -> GoalProgress? {
    guard let goal, goal > 0 else { return nil }
    return GoalProgress(current: current, goal: goal, direction: direction)
  }
}
