import Foundation
import SwiftData

enum AppDataReset {
  static let suppressSampleSeedingKey = "app.data.suppressSampleSeeding"

  /// Wipes all counters/entries and launches the fresh-install onboarding flow.
  @MainActor
  static func resetAll(in context: ModelContext) {
    // Cascade delete clears entries — do not fetch/delete `CounterEntry` afterward
    // (those objects are already invalidated and will crash).
    for counter in (try? context.fetch(FetchDescriptor<CustomCounter>())) ?? [] {
      context.delete(counter)
    }
    AppLog.attempt("Save full data reset") { try context.save() }

    QuickAddSessionStore.shared.reset()
    // Don't reload widgets yet — the extension would open the App Group store while we're
    // still mutating it (and Watch sync may write the same file), which can hang the UI.
    WidgetSnapshot.clear(reloadWidgets: false)
    UserDefaults.standard.set(false, forKey: suppressSampleSeedingKey)
    FreshInstallOnboarding.requestPresentation()

    WidgetSnapshot.reloadTimelines()
    WatchSyncEngine.publishFullSnapshot(in: context)
  }

  /// Seeds chosen starters after onboarding, then publishes widgets / watch.
  @MainActor
  static func finishFreshInstall(
    drafts: [FreshInstallStarterDraft],
    colorPack: CounterColorPack,
    in context: ModelContext
  ) {
    AppAppearancePreference.sharedDefaults.set(colorPack.rawValue, forKey: AppAppearancePreference.colorPackKey)

    if !SampleDataSeeder.hasAnyCounters(in: context) {
      SampleDataSeeder.seed(drafts: drafts, in: context)
      publishDefaultWidgetSnapshot(from: context)
    } else {
      WidgetSnapshot.reloadTimelines()
    }

    FreshInstallOnboarding.markCompleted()
    WatchSyncEngine.publishFullSnapshot(in: context)
  }

  @MainActor
  private static func publishDefaultWidgetSnapshot(from context: ModelContext) {
    let descriptor = FetchDescriptor<CustomCounter>(
      sortBy: [SortDescriptor(\.sortOrder)]
    )
    guard let counter = (try? context.fetch(descriptor))?.first else {
      WidgetSnapshot.reloadTimelines()
      return
    }
    // Writes defaults and schedules a deferred timeline reload.
    WidgetSnapshot.publish(
      title: counter.name,
      heroValue: counter.currentProgress()?.heroValue
        ?? CounterFormatting.amount(counter.currentTotal())
    )
  }
}
