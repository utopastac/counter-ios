import Foundation

/// Gates the two-step fresh-install flow (colour pack → starter counters).
///
/// Shown on first empty launch, after "Reset all data", or as a Development
/// preview that never reseeds counters. Existing installs migrate to "completed"
/// so upgrading users are not interrupted.
enum FreshInstallOnboarding {
  static let hasCompletedKey = "app.onboarding.freshInstallCompleted"
  /// Development-only overlay; does not clear `hasCompletedKey` or reseed data.
  static let previewActiveKey = "app.onboarding.previewActive"

  static var hasCompleted: Bool {
    UserDefaults.standard.bool(forKey: hasCompletedKey)
  }

  static var isPreviewActive: Bool {
    UserDefaults.standard.bool(forKey: previewActiveKey)
  }

  static var needsPresentation: Bool {
    !hasCompleted
  }

  /// Call once at bootstrap. Writes the key if it was never set:
  /// - empty store → show onboarding
  /// - existing counters → skip (upgrade path)
  static func migrateIfNeeded(hasCounters: Bool) {
    guard UserDefaults.standard.object(forKey: hasCompletedKey) == nil else { return }
    UserDefaults.standard.set(hasCounters, forKey: hasCompletedKey)
  }

  static func markCompleted() {
    UserDefaults.standard.set(true, forKey: hasCompletedKey)
  }

  /// Re-shows onboarding after a full data reset (will seed on finish).
  static func requestPresentation() {
    UserDefaults.standard.set(false, forKey: hasCompletedKey)
    UserDefaults.standard.set(false, forKey: previewActiveKey)
  }

  /// Opens the flow from Development without touching counters on finish.
  static func requestPreview() {
    UserDefaults.standard.set(true, forKey: previewActiveKey)
  }

  static func endPreview() {
    UserDefaults.standard.set(false, forKey: previewActiveKey)
  }

  /// Templates offered during step 2 (excludes blank).
  static var starterTemplates: [CounterTemplate] {
    [.calories, .protein, .money, .water, .coffee, .workouts]
  }

  /// Matches the historic default set (Calories, Protein, Money).
  static var defaultSelectedTemplates: Set<CounterTemplate> {
    [.calories, .protein, .money]
  }

  static func defaultDrafts() -> [FreshInstallStarterDraft] {
    starterTemplates.map(FreshInstallStarterDraft.default(for:))
  }
}

/// Editable starter counter offered during fresh-install onboarding.
struct FreshInstallStarterDraft: Identifiable, Hashable {
  var template: CounterTemplate
  var isSelected: Bool
  var name: String
  var unit: String
  var goalText: String
  var resetPeriod: CounterResetPeriod
  var resetAnchorDay: Int
  var goalDirection: GoalDirection
  var buttonValues: [Double]
  /// Palette slot used for the selected card fill (and seeded counter colour).
  var paletteIndex: Int
  var progressRingStyleRaw: String? = nil
  var progressRingWidthRaw: String? = nil
  var progressRingGlowRaw: String? = nil

  var id: String { template.rawValue }

  var goal: Double {
    Double(goalText.replacingOccurrences(of: ",", with: "")) ?? 0
  }

  var subtitle: String {
    let amount = goal > 0 ? CounterFormatting.amount(goal) : goalText
    return "\(amount) \(unit) \(resetPeriod.rawValue)"
  }

  static func `default`(for template: CounterTemplate) -> FreshInstallStarterDraft {
    switch template {
    case .blank:
      FreshInstallStarterDraft(
        template: .blank,
        isSelected: false,
        name: "",
        unit: "",
        goalText: "",
        resetPeriod: .daily,
        resetAnchorDay: CounterResetPeriod.daily.defaultAnchorDay(),
        goalDirection: .countUp,
        buttonValues: QuickAddConfiguration.defaultCounterPresets,
        paletteIndex: 0
      )
    case .calories:
      FreshInstallStarterDraft(
        template: .calories,
        isSelected: true,
        name: "Calories",
        unit: "kCal",
        goalText: "2000",
        resetPeriod: .daily,
        resetAnchorDay: CounterResetPeriod.daily.defaultAnchorDay(),
        goalDirection: .countDown,
        buttonValues: SampleDataSeeder.mockQuickAddPresets,
        paletteIndex: 0
      )
    case .protein:
      FreshInstallStarterDraft(
        template: .protein,
        isSelected: true,
        name: "Protein",
        unit: "g",
        goalText: "150",
        resetPeriod: .daily,
        resetAnchorDay: CounterResetPeriod.daily.defaultAnchorDay(),
        goalDirection: .countUp,
        buttonValues: CounterTemplate.protein.defaultPresets,
        paletteIndex: 4
      )
    case .money:
      FreshInstallStarterDraft(
        template: .money,
        isSelected: true,
        name: "Money",
        unit: "$",
        goalText: "2000",
        resetPeriod: .monthly,
        resetAnchorDay: CounterResetPeriod.monthly.defaultAnchorDay(),
        goalDirection: .countDown,
        buttonValues: CounterTemplate.money.defaultPresets,
        paletteIndex: 1
      )
    case .water:
      FreshInstallStarterDraft(
        template: .water,
        isSelected: false,
        name: "Water",
        unit: "glasses",
        goalText: "8",
        resetPeriod: .daily,
        resetAnchorDay: CounterResetPeriod.daily.defaultAnchorDay(),
        goalDirection: .countUp,
        buttonValues: CounterTemplate.water.defaultPresets,
        paletteIndex: 6
      )
    case .coffee:
      FreshInstallStarterDraft(
        template: .coffee,
        isSelected: false,
        name: "Coffee",
        unit: "cups",
        goalText: "3",
        resetPeriod: .daily,
        resetAnchorDay: CounterResetPeriod.daily.defaultAnchorDay(),
        goalDirection: .countUp,
        buttonValues: CounterTemplate.coffee.defaultPresets,
        paletteIndex: 7
      )
    case .workouts:
      FreshInstallStarterDraft(
        template: .workouts,
        isSelected: false,
        name: "Workouts",
        unit: "sessions",
        goalText: "4",
        resetPeriod: .weekly,
        resetAnchorDay: CounterResetPeriod.weekly.defaultAnchorDay(),
        goalDirection: .countUp,
        buttonValues: CounterTemplate.workouts.defaultPresets,
        paletteIndex: 5
      )
    }
  }
}
