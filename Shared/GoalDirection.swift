import Foundation

enum GoalDirection: String, Codable, CaseIterable, Identifiable {
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
    min(max(fractionComplete, 0), 1)
  }

  var overflowRingFraction: Double {
    guard fractionComplete > 1 else { return 0 }
    return min(fractionComplete - 1, 1)
  }

  var isOverGoal: Bool {
    current > goal
  }

  var percentComplete: Int {
    Int((fractionComplete * 100).rounded())
  }

  var heroValue: String {
    switch direction {
    case .countUp:
      return "\(current)"
    case .countDown:
      return "\(delta)"
    }
  }

  var heroCaption: String {
    switch direction {
    case .countUp:
      return "of \(goal)"
    case .countDown:
      return "remaining"
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
}
