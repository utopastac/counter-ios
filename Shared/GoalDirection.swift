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

  var summary: String {
    switch self {
    case .countUp: "Track progress toward a target"
    case .countDown: "Track remaining toward a limit"
    }
  }
}

nonisolated struct GoalProgress {
  let current: Int
  let goal: Int
  let direction: GoalDirection

  var delta: Int {
    goal - current
  }

  var fractionComplete: Double {
    guard goal > 0 else { return 0 }
    return Double(current) / Double(goal)
  }

  var ringFraction: Double {
    guard goal > 0 else { return 0 }
    switch direction {
    case .countUp:
      return min(max(Double(current) / Double(goal), 0), 1)
    case .countDown:
      return min(max(Double(delta) / Double(goal), 0), 1)
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

  var heroValue: String {
    "\(current)"
  }

  var heroCaption: String {
    switch direction {
    case .countUp:
      return "of \(goal)"
    case .countDown:
      return "remaining"
    }
  }

  var heroSubtitle: String {
    switch direction {
    case .countUp:
      return "\(delta) to go"
    case .countDown:
      return "\(delta) remaining"
    }
  }

  var statsSummaryValue: String {
    "\(delta)"
  }

  var statsSummaryLabel: String {
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
      return delta >= 0 ? "Progress" : "Over goal"
    case .countDown:
      return "Budget used"
    }
  }

  var detailLabel: String {
    switch direction {
    case .countUp:
      return delta >= 0 ? "\(current) / \(goal)" : "\(-delta) over \(goal)"
    case .countDown:
      return "\(delta) remaining"
    }
  }

  var listSubtitle: String {
    switch direction {
    case .countUp:
      return "\(current) logged · \(goal) goal"
    case .countDown:
      return "\(current) used · \(goal) goal"
    }
  }

  var summaryValue: String {
    switch direction {
    case .countUp:
      return "\(current)"
    case .countDown:
      return "\(delta)"
    }
  }

  var summaryCaption: String {
    switch direction {
    case .countUp:
      return "logged"
    case .countDown:
      return "remaining"
    }
  }

  var metricRows: [(label: String, value: String)] {
    switch direction {
    case .countUp:
      return [
        ("Goal", "\(goal)"),
        ("Progress", "\(current)"),
        ("To go", "\(delta)")
      ]
    case .countDown:
      return [
        ("Goal", "\(goal)"),
        ("Used", "\(current)"),
        ("Remaining", "\(delta)")
      ]
    }
  }
}

nonisolated enum GoalProgressCalculator {
  static func progress(current: Int, goal: Int?, direction: GoalDirection) -> GoalProgress? {
    guard let goal, goal > 0 else { return nil }
    return GoalProgress(current: current, goal: goal, direction: direction)
  }

  /// Always returns progress suitable for rendering a ring, even when no goal is set.
  static func ringDisplay(current: Int, goal: Int?, direction: GoalDirection) -> GoalProgress {
    if let goal, goal > 0 {
      return GoalProgress(current: current, goal: goal, direction: direction)
    }
    return GoalProgress(current: 0, goal: 1, direction: .countUp)
  }
}
