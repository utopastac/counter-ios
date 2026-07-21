import Foundation
import SwiftData
import Testing

@MainActor
struct AppDataResetTests {
  @Test func resetAllClearsCountersAndRequestsOnboarding() throws {
    let container = TestModelContainer.make()
    let context = container.mainContext

    let existing = CustomCounter(name: "Custom", goal: 10)
    context.insert(existing)
    context.insert(CounterEntry(value: 3, counter: existing))
    try context.save()

    UserDefaults.standard.set(true, forKey: AppDataReset.suppressSampleSeedingKey)
    FreshInstallOnboarding.markCompleted()

    AppDataReset.resetAll(in: context)

    let counters = try context.fetch(
      FetchDescriptor<CustomCounter>(sortBy: [SortDescriptor(\.sortOrder)])
    )
    #expect(counters.isEmpty)
    #expect(UserDefaults.standard.bool(forKey: AppDataReset.suppressSampleSeedingKey) == false)
    #expect(FreshInstallOnboarding.needsPresentation)

    let entries = try context.fetch(FetchDescriptor<CounterEntry>())
    #expect(entries.isEmpty)
  }

  @Test func finishFreshInstallSeedsSelectedDraftsAndCompletesOnboarding() throws {
    let container = TestModelContainer.make()
    let context = container.mainContext
    FreshInstallOnboarding.requestPresentation()

    var calories = FreshInstallStarterDraft.default(for: .calories)
    calories.goalText = "1800"
    calories.name = "Daily calories"
    var water = FreshInstallStarterDraft.default(for: .water)
    water.isSelected = true

    AppDataReset.finishFreshInstall(
      drafts: [calories, water],
      colorPack: .ocean,
      in: context
    )

    let counters = try context.fetch(
      FetchDescriptor<CustomCounter>(sortBy: [SortDescriptor(\.sortOrder)])
    )
    #expect(counters.map(\.name) == ["Daily calories", "Water"])
    #expect(counters.first?.goal == 1800)
    #expect(AppAppearancePreference.colorPack == .ocean)
    #expect(FreshInstallOnboarding.hasCompleted)
  }

  @Test func finishFreshInstallSkipsSeedingWhenCountersAlreadyExist() throws {
    let container = TestModelContainer.make()
    let context = container.mainContext
    let existing = CustomCounter(name: "Keep me", goal: 5)
    context.insert(existing)
    try context.save()
    FreshInstallOnboarding.requestPresentation()

    AppDataReset.finishFreshInstall(
      drafts: FreshInstallOnboarding.defaultDrafts(),
      colorPack: .neon,
      in: context
    )

    let counters = try context.fetch(
      FetchDescriptor<CustomCounter>(sortBy: [SortDescriptor(\.sortOrder)])
    )
    #expect(counters.map(\.name) == ["Keep me"])
    #expect(AppAppearancePreference.colorPack == .neon)
    #expect(FreshInstallOnboarding.hasCompleted)
  }

  @Test func migrateMarksExistingInstallsComplete() {
    UserDefaults.standard.removeObject(forKey: FreshInstallOnboarding.hasCompletedKey)
    FreshInstallOnboarding.migrateIfNeeded(hasCounters: true)
    #expect(FreshInstallOnboarding.hasCompleted)

    UserDefaults.standard.removeObject(forKey: FreshInstallOnboarding.hasCompletedKey)
    FreshInstallOnboarding.migrateIfNeeded(hasCounters: false)
    #expect(FreshInstallOnboarding.needsPresentation)
  }

  @Test func requestPreviewDoesNotClearCompletionOrSeed() throws {
    let container = TestModelContainer.make()
    let context = container.mainContext
    let existing = CustomCounter(name: "Keep me", goal: 5)
    context.insert(existing)
    try context.save()

    FreshInstallOnboarding.markCompleted()
    FreshInstallOnboarding.endPreview()
    FreshInstallOnboarding.requestPreview()

    #expect(FreshInstallOnboarding.hasCompleted)
    #expect(FreshInstallOnboarding.isPreviewActive)

    let counters = try context.fetch(FetchDescriptor<CustomCounter>())
    #expect(counters.map(\.name) == ["Keep me"])

    FreshInstallOnboarding.endPreview()
    #expect(!FreshInstallOnboarding.isPreviewActive)
  }
}
