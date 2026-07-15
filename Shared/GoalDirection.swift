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

struct GoalProgress {
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

  /// Magnitude (0, 1] of the current lap once progress has gone past 100%, wound clockwise
  /// on top of the completed base ring — mirrors how Apple's Activity rings keep wrapping
  /// around themselves instead of stopping at one extra loop.
  ///
  /// Wraps with `truncatingRemainder` rather than capping, so 150%, 250%, 350%… all read as
  /// "how far into the current lap", and the ring can loop indefinitely.
  var overflowRingFraction: Double {
    guard fractionComplete > 1 else { return 0 }
    return Self.loopFraction(of: fractionComplete - 1)
  }

  /// Magnitude (0, 1] of the first lap wound counter-clockwise from 12 o'clock once progress
  /// has dropped below 0% (e.g. a negative logged total). Drawn plainly, the same way the
  /// normal fill is drawn for the first 0...100% lap — only the *second* backward lap and
  /// beyond (`underflowOverlapFraction`) gets the overlap outline treatment.
  var underflowRingFraction: Double {
    guard fractionComplete < 0 else { return 0 }
    return min(-fractionComplete, 1)
  }

  /// Magnitude (0, 1] of the current lap once progress has gone past one full loop below 0%,
  /// wound counter-clockwise on top of the completed first backward lap. Mirrors
  /// `overflowRingFraction` and loops indefinitely the same way.
  var underflowOverlapFraction: Double {
    guard fractionComplete < -1 else { return 0 }
    return Self.loopFraction(of: -fractionComplete - 1)
  }

  private static func loopFraction(of excess: Double) -> Double {
    let wrapped = excess.truncatingRemainder(dividingBy: 1)
    return wrapped == 0 ? 1 : wrapped
  }

  var isOverGoal: Bool {
    current > goal
  }

  var isUnderZero: Bool {
    fractionComplete < 0
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

enum GoalProgressCalculator {
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
