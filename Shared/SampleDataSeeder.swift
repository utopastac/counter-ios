import Foundation
import SwiftData

/// Seeds the default counters when none exist.
enum SampleDataSeeder {
  /// Quick-add presets shown in the design mockups.
  static let mockQuickAddPresets: [Double] = QuickAddConfiguration.defaultCaloriePresets

  @MainActor
  static func seedIfNeeded(in context: ModelContext) {
    guard !UserDefaults.standard.bool(forKey: AppDataReset.suppressSampleSeedingKey) else { return }
    guard !FreshInstallOnboarding.needsPresentation else { return }
    guard !hasAnyCounters(in: context) else { return }

    seedDefaults(in: context)
    WatchSyncEngine.publishFullSnapshot(in: context)
  }

  /// Inserts the three default counters (Calories, Protein, Money) with zero totals.
  /// Caller is responsible for ensuring the store is empty (or accepting duplicates).
  @MainActor
  static func seedDefaults(in context: ModelContext) {
    let drafts = FreshInstallOnboarding.defaultDrafts().filter(\.isSelected)
    seed(drafts: drafts, in: context)
  }

  /// Inserts selected starter drafts (order preserved).
  @MainActor
  static func seed(drafts: [FreshInstallStarterDraft], in context: ModelContext) {
    let selected = drafts.filter { $0.isSelected && $0.template != .blank }
    guard !selected.isEmpty else { return }

    for (index, draft) in selected.enumerated() {
      seed(draft: draft, sortOrder: Double(index), in: context)
    }

    AppLog.attempt("Save seeded sample data") { try context.save() }
  }

  static func hasAnyCounters(in context: ModelContext) -> Bool {
    var descriptor = FetchDescriptor<CustomCounter>()
    descriptor.fetchLimit = 1
    return (try? context.fetch(descriptor).isEmpty == false) ?? false
  }

  private static func seed(draft: FreshInstallStarterDraft, sortOrder: Double, in context: ModelContext) {
    let template = draft.template
    let counter = CustomCounter(
      name: draft.name,
      unit: draft.unit,
      buttonValues: draft.buttonValues,
      goal: draft.goal > 0 ? draft.goal : nil,
      resetPeriod: draft.resetPeriod,
      resetAnchorDay: draft.resetAnchorDay,
      goalDirection: draft.goalDirection,
      sortOrder: sortOrder
    )
    counter.createdAt = createdAt(for: template)
    counter.paletteIndex = CustomCounter.normalizedPaletteIndex(draft.paletteIndex)
    context.insert(counter)
  }

  private static func createdAt(for template: CounterTemplate) -> Date {
    switch template {
    case .blank, .calories:
      .distantPast
    case .protein:
      .now.addingTimeInterval(-120)
    case .money:
      .now.addingTimeInterval(-60)
    case .water:
      .now.addingTimeInterval(-30)
    case .coffee:
      .now.addingTimeInterval(-15)
    case .workouts:
      .now.addingTimeInterval(-10)
    }
  }
}
