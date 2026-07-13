import Foundation
import SwiftData

@Model
final class CustomCounter {
  var id: UUID
  var name: String
  var buttonValues: [Int]
  var sliderMax: Int
  var createdAt: Date
  var goal: Int?
  var resetPeriodRaw: String = CounterResetPeriod.daily.rawValue
  var resetAnchorDay: Int = 1
  var goalDirectionRaw: String = GoalDirection.countUp.rawValue
  @Relationship(deleteRule: .cascade, inverse: \CounterEntry.counter)
  var entries: [CounterEntry]

  init(
    name: String,
    buttonValues: [Int] = [10, 20, 50, 100, 200],
    sliderMax: Int = 100,
    goal: Int? = nil,
    resetPeriod: CounterResetPeriod = .daily,
    resetAnchorDay: Int = 1,
    goalDirection: GoalDirection = .countUp
  ) {
    self.id = UUID()
    self.name = name
    self.buttonValues = buttonValues
    self.sliderMax = sliderMax
    self.createdAt = .now
    self.goal = goal
    self.resetPeriodRaw = resetPeriod.rawValue
    self.resetAnchorDay = resetAnchorDay
    self.goalDirectionRaw = goalDirection.rawValue
    self.entries = []
  }

  var goalDirection: GoalDirection {
    get { GoalDirection(rawValue: goalDirectionRaw) ?? .countUp }
    set { goalDirectionRaw = newValue.rawValue }
  }

  var resetPeriod: CounterResetPeriod {
    get { CounterResetPeriod(rawValue: resetPeriodRaw) ?? .daily }
    set { resetPeriodRaw = newValue.rawValue }
  }

  var effectiveResetAnchorDay: Int {
    switch resetPeriod {
    case .daily:
      return 1
    case .weekly:
      return min(max(resetAnchorDay, 1), 7)
    case .monthly:
      return min(max(resetAnchorDay, 1), 31)
    }
  }

  var effectiveSliderMax: Int {
    sliderMax > 0 ? sliderMax : 100
  }

  var hasGoal: Bool {
    guard let goal else { return false }
    return goal > 0
  }

  var effectiveGoal: Int? {
    guard let goal, goal > 0 else { return nil }
    return goal
  }
}
