import Foundation
import SwiftData

@Model
final class AppSettings {
  var id: UUID
  var calorieButtonValues: [Int]
  var calorieSliderMax: Int
  var calorieGoal: Int?
  var calorieResetPeriodRaw: String = CounterResetPeriod.daily.rawValue
  var calorieResetAnchorDay: Int = 1
  var calorieGoalDirectionRaw: String = GoalDirection.countDown.rawValue

  init(
    calorieButtonValues: [Int] = [10, 20, 50, 100, 200, 500],
    calorieSliderMax: Int = 2000,
    calorieGoal: Int? = nil,
    calorieResetPeriod: CounterResetPeriod = .daily,
    calorieResetAnchorDay: Int = 1,
    calorieGoalDirection: GoalDirection = .countDown
  ) {
    self.id = UUID()
    self.calorieButtonValues = calorieButtonValues
    self.calorieSliderMax = calorieSliderMax
    self.calorieGoal = calorieGoal
    self.calorieResetPeriodRaw = calorieResetPeriod.rawValue
    self.calorieResetAnchorDay = calorieResetAnchorDay
    self.calorieGoalDirectionRaw = calorieGoalDirection.rawValue
  }

  var calorieResetPeriod: CounterResetPeriod {
    get { CounterResetPeriod(rawValue: calorieResetPeriodRaw) ?? .daily }
    set { calorieResetPeriodRaw = newValue.rawValue }
  }

  var calorieGoalDirection: GoalDirection {
    get { GoalDirection(rawValue: calorieGoalDirectionRaw) ?? .countDown }
    set { calorieGoalDirectionRaw = newValue.rawValue }
  }

  var effectiveCalorieResetAnchorDay: Int {
    switch calorieResetPeriod {
    case .daily:
      return 1
    case .weekly:
      return min(max(calorieResetAnchorDay, 1), 7)
    case .monthly:
      return min(max(calorieResetAnchorDay, 1), 31)
    }
  }

  var effectiveCalorieGoal: Int? {
    guard let calorieGoal, calorieGoal > 0 else { return nil }
    return calorieGoal
  }

  var effectiveCalorieSliderMax: Int {
    calorieSliderMax > 0 ? calorieSliderMax : 2000
  }
}
