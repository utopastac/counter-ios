import Foundation
import SwiftData

@Model
final class CustomCounter {
  static let defaultCalorieGoal = 2200
  static let defaultButtonValues: [Int] = [1, 2, 5, 10, 20, 25, 50, 75, 100]
  static let untitledName = "Untitled"

  static func normalizedName(from raw: String) -> String {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? untitledName : trimmed
  }

  var id: UUID
  var name: String
  var buttonValues: [Int]
  var sliderMax: Int
  var createdAt: Date
  var goal: Int?
  var resetPeriodRaw: String = CounterResetPeriod.daily.rawValue
  var resetAnchorDay: Int = 1
  var goalDirectionRaw: String = GoalDirection.countUp.rawValue
  var paletteIndex: Int = 0
  @Relationship(deleteRule: .cascade, inverse: \CounterEntry.counter)
  var entries: [CounterEntry]

  init(
    name: String,
    buttonValues: [Int]? = nil,
    sliderMax: Int = 100,
    goal: Int? = nil,
    resetPeriod: CounterResetPeriod = .daily,
    resetAnchorDay: Int = 1,
    goalDirection: GoalDirection = .countUp,
    paletteIndex: Int = 0
  ) {
    self.id = UUID()
    self.name = name
    self.buttonValues = buttonValues ?? Self.defaultButtonValues
    self.sliderMax = sliderMax
    self.createdAt = .now
    self.goal = goal
    self.resetPeriodRaw = resetPeriod.rawValue
    self.resetAnchorDay = resetAnchorDay
    self.goalDirectionRaw = goalDirection.rawValue
    self.paletteIndex = Self.normalizedPaletteIndex(paletteIndex)
    self.entries = []
  }

  var effectivePaletteIndex: Int {
    Self.normalizedPaletteIndex(paletteIndex)
  }

  static let paletteSlotCount = 10

  static func normalizedPaletteIndex(_ index: Int) -> Int {
    let count = paletteSlotCount
    return ((index % count) + count) % count
  }

  /// The palette slot a newly-created counter should default to, given how many counters
  /// already exist — cycles through every slot before repeating. Named for its one call site
  /// (assigning a new counter's initial color) rather than reused as a generic modulo helper.
  static func nextPaletteIndex(forExistingCount count: Int) -> Int {
    normalizedPaletteIndex(count)
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
