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
  var progressRingWidthRaw: String? = nil
  var progressRingGlowRaw: String? = nil
  var historyAverageActiveDaysOnlyRaw: String? = nil
  var historyPerPeriodRaw: String? = nil
  var headerDisplayRaw: String? = nil

  var id: String { template.rawValue }

  /// Parsed goal for seeding. Uses the same positive-amount rules as create/settings forms.
  var goal: Double {
    let cleaned = goalText.replacingOccurrences(of: ",", with: "")
    return AmountInput.parsePositiveAmount(cleaned) ?? 0
  }

  var subtitle: String {
    let amount = goal > 0 ? CounterFormatting.amount(goal) : goalText
    return "\(amount) \(unit) \(resetPeriod.rawValue)"
  }

  /// Builds a draft from `CounterTemplate` so create-form and onboarding starters can't drift.
  /// Only selection state and onboarding palette slots are draft-specific.
  static func `default`(for template: CounterTemplate) -> FreshInstallStarterDraft {
    let period = template.defaultResetPeriod
    let goalText = template.defaultGoal.map(CounterFormatting.editingText(for:)) ?? ""
    return FreshInstallStarterDraft(
      template: template,
      isSelected: FreshInstallOnboarding.defaultSelectedTemplates.contains(template),
      name: template.defaultName,
      unit: template.defaultUnit,
      goalText: goalText,
      resetPeriod: period,
      resetAnchorDay: period.defaultAnchorDay(),
      goalDirection: template.defaultGoalDirection,
      buttonValues: template.defaultPresets,
      paletteIndex: defaultPaletteIndex(for: template)
    )
  }

  /// Stable onboarding card colours — not part of `CounterTemplate` because create-form
  /// assigns palette via `CustomCounter.nextPaletteIndex` instead.
  private static func defaultPaletteIndex(for template: CounterTemplate) -> Int {
    switch template {
    case .blank, .calories: 0
    case .money: 1
    case .protein: 4
    case .workouts: 5
    case .water: 6
    case .coffee: 7
    }
  }
}
