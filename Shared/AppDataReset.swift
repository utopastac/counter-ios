import Foundation
import SwiftData

enum AppDataReset {
  static let suppressSampleSeedingKey = "app.data.suppressSampleSeeding"

  /// Set by the Settings UI before flipping onboarding on. `ContentView` performs the
  /// wipe once the pager has unmounted (see `performPendingWipeIfNeeded`).
  @MainActor
  private static var pendingWipeAfterOnboardingPresentation = false

  /// UI entry point: show onboarding first, wipe after the pager is gone.
  /// Caller should disable animations around this if the pager is on screen.
  @MainActor
  static func requestResetFromUI() {
    pendingWipeAfterOnboardingPresentation = true
    UserDefaults.standard.set(false, forKey: suppressSampleSeedingKey)
    FreshInstallOnboarding.requestPresentation()
  }

  /// Called from `ContentView` when fresh-install chrome appears.
  @MainActor
  static func performPendingWipeIfNeeded(in context: ModelContext) {
    guard pendingWipeAfterOnboardingPresentation else { return }
    pendingWipeAfterOnboardingPresentation = false
    wipeStore(in: context)
  }

  /// Wipes all counters/entries and launches the fresh-install onboarding flow.
  /// Prefer `requestResetFromUI()` from SwiftUI so the pager unmounts before invalidation.
  @MainActor
  static func resetAll(in context: ModelContext) {
    UserDefaults.standard.set(false, forKey: suppressSampleSeedingKey)
    FreshInstallOnboarding.requestPresentation()
    wipeStore(in: context)
  }

  @MainActor
  private static func wipeStore(in context: ModelContext) {
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
