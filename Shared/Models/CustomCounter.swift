import Foundation
import SwiftData

@Model
final class CustomCounter {
  static let defaultCalorieGoal: Double = 2200
  static let defaultButtonValues: [Double] = [1, 2, 5, 10, 20, 25, 50, 75, 100]
  static let untitledName = "Untitled"

  static func normalizedName(from raw: String) -> String {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? untitledName : trimmed
  }

  static func normalizedUnit(from raw: String) -> String {
    String(raw.trimmingCharacters(in: .whitespacesAndNewlines).prefix(12))
  }

  var id: UUID
  var name: String
  var unit: String = ""
  var buttonValues: [Double]
  var createdAt: Date
  /// Lower values appear first in the pager and list.
  var sortOrder: Double = 0
  /// `nil` / non-positive means no goal.
  var goal: Double?
  var resetPeriodRaw: String = CounterResetPeriod.daily.rawValue
  var resetAnchorDay: Int = 1
  var goalDirectionRaw: String = GoalDirection.countUp.rawValue
  var paletteIndex: Int = 0
  @Relationship(deleteRule: .cascade, inverse: \CounterEntry.counter)
  var entries: [CounterEntry]

  init(
    name: String,
    unit: String = "",
    buttonValues: [Double]? = nil,
    goal: Double? = nil,
    resetPeriod: CounterResetPeriod = .daily,
    resetAnchorDay: Int = 1,
    goalDirection: GoalDirection = .countUp,
    paletteIndex: Int = 0,
    sortOrder: Double? = nil
  ) {
    let createdAt = Date.now
    self.id = UUID()
    self.name = name
    self.unit = Self.normalizedUnit(from: unit)
    self.buttonValues = CounterAmount.rounded(buttonValues ?? Self.defaultButtonValues)
    self.createdAt = createdAt
    self.sortOrder = sortOrder ?? createdAt.timeIntervalSinceReferenceDate
    self.goal = goal.map(CounterAmount.rounded)
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

  static func nextPaletteIndex(forExistingCount count: Int) -> Int {
    normalizedPaletteIndex(count)
  }

  static func nextSortOrder(forExisting counters: [CustomCounter]) -> Double {
    (counters.map(\.sortOrder).max() ?? 0) + 1
  }

  var goalDirection: GoalDirection {
    get { GoalDirection(rawValue: goalDirectionRaw) ?? .countUp }
    set { goalDirectionRaw = newValue.rawValue }
  }

  var resetPeriod: CounterResetPeriod {
    get { CounterResetPeriod(rawValue: resetPeriodRaw) ?? .daily }
    set { resetPeriodRaw = newValue.rawValue }
  }

  var effectiveUnit: String {
    Self.normalizedUnit(from: unit)
  }

  var presetAmounts: [Double] {
    get { buttonValues }
    set { buttonValues = CounterAmount.rounded(newValue) }
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

  var hasGoal: Bool {
    guard let goal else { return false }
    return goal > 0
  }

  var effectiveGoal: Double? {
    guard let goal, goal > 0 else { return nil }
    return goal
  }
}
