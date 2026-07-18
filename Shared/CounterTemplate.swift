import Foundation

/// Starter templates offered when creating a counter. Applying a template fills name, goal,
/// direction, unit, and quick-add presets — the user can still edit everything before saving.
nonisolated enum CounterTemplate: String, CaseIterable, Identifiable {
  case blank
  case calories
  case protein
  case money
  case water

  var id: String { rawValue }

  var label: String {
    switch self {
    case .blank: "Blank"
    case .calories: "Calories"
    case .protein: "Protein"
    case .money: "Money"
    case .water: "Water"
    }
  }

  var defaultName: String {
    switch self {
    case .blank: ""
    case .calories: "Calories"
    case .protein: "Protein"
    case .money: "Money"
    case .water: "Water"
    }
  }

  var defaultUnit: String {
    switch self {
    case .blank: ""
    case .calories: "kcal"
    case .protein: "g"
    case .money: "$"
    case .water: "cups"
    }
  }

  var defaultGoal: Double? {
    switch self {
    case .blank: nil
    case .calories: 2200
    case .protein: 150
    case .money: 100
    case .water: 8
    }
  }

  var defaultGoalDirection: GoalDirection {
    switch self {
    case .blank, .protein, .water: .countUp
    case .calories, .money: .countDown
    }
  }

  var defaultPresets: [Double] {
    switch self {
    case .blank:
      QuickAddConfiguration.defaultCounterPresets
    case .calories:
      QuickAddConfiguration.defaultCaloriePresets
    case .protein:
      [5, 10, 15, 20, 25, 30, 40, 50, 100]
    case .money:
      [1, 2, 5, 10, 20, 25, 50, 75, 100]
    case .water:
      [0.5, 1, 1.5, 2, 3, 4, 5, 6, 8]
    }
  }
}
