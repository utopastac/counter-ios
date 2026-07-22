import Foundation
import Testing

struct AppAppearancePreferenceTests {
  private func withClearedKey(
    _ key: String,
    in defaults: UserDefaults,
    perform: () -> Void
  ) {
    let previous = defaults.object(forKey: key)
    defaults.removeObject(forKey: key)
    defer {
      if let previous {
        defaults.set(previous, forKey: key)
      } else {
        defaults.removeObject(forKey: key)
      }
    }
    perform()
  }

  private func withValue(
    _ value: Any?,
    forKey key: String,
    in defaults: UserDefaults,
    perform: () -> Void
  ) {
    let previous = defaults.object(forKey: key)
    if let value {
      defaults.set(value, forKey: key)
    } else {
      defaults.removeObject(forKey: key)
    }
    defer {
      if let previous {
        defaults.set(previous, forKey: key)
      } else {
        defaults.removeObject(forKey: key)
      }
    }
    perform()
  }

  @Test func hapticsDefaultToEnabledWhenUnset() {
    withClearedKey(AppAppearancePreference.hapticsEnabledKey, in: .standard) {
      #expect(AppAppearancePreference.isHapticsEnabled)
    }
  }

  @Test func tintDefaultsToEnabledWhenUnset() {
    withClearedKey(
      AppAppearancePreference.tintEnabledKey,
      in: AppAppearancePreference.sharedDefaults
    ) {
      #expect(AppAppearancePreference.isTintEnabled)
    }
  }

  @Test func colorPackFallsBackToMutedForUnknownRawValue() {
    withValue(
      "not-a-pack",
      forKey: AppAppearancePreference.colorPackKey,
      in: AppAppearancePreference.sharedDefaults
    ) {
      #expect(AppAppearancePreference.colorPack == .muted)
    }
  }

  @Test func progressRingWidthFallsBackToBalancedForUnknownRawValue() {
    withValue(
      "extra-chunky",
      forKey: AppAppearancePreference.progressRingWidthKey,
      in: AppAppearancePreference.sharedDefaults
    ) {
      #expect(AppAppearancePreference.progressRingWidth == .balanced)
    }
  }

  @Test func progressRingStyleFallsBackToSolidForUnknownRawValue() {
    withValue(
      "dashed",
      forKey: AppAppearancePreference.progressRingStyleKey,
      in: AppAppearancePreference.sharedDefaults
    ) {
      #expect(AppAppearancePreference.progressRingStyle == .solid)
    }
  }

  @Test func progressRingStyleMigratesRetiredGlowCaseToSolid() {
    withValue(
      "glow",
      forKey: AppAppearancePreference.progressRingStyleKey,
      in: AppAppearancePreference.sharedDefaults
    ) {
      #expect(AppAppearancePreference.progressRingStyle == .solid)
    }
  }

  @Test func progressRingGlowDefaultsToOffWhenUnset() {
    AppAppearancePreference.sharedDefaults.removeObject(
      forKey: AppAppearancePreference.progressRingGlowEnabledKey
    )
    #expect(!AppAppearancePreference.isProgressRingGlowEnabled)
  }

  @Test func fontPackFallsBackToDefaultForUnknownRawValue() {
    withValue(
      "handwriting",
      forKey: AppAppearancePreference.fontPackKey,
      in: AppAppearancePreference.sharedDefaults
    ) {
      #expect(AppAppearancePreference.fontPack == .default)
    }
  }

  @Test func soundStyleFallsBackToOffForUnknownRawValue() {
    withValue(
      "boom",
      forKey: AppAppearancePreference.soundStyleKey,
      in: .standard
    ) {
      #expect(AppAppearancePreference.soundStyle == .off)
    }
  }

  @Test func defaultResetPeriodFallsBackToDailyForUnknownRawValue() {
    withValue(
      "fortnightly",
      forKey: AppAppearancePreference.defaultResetPeriodKey,
      in: .standard
    ) {
      #expect(AppAppearancePreference.defaultResetPeriod == .daily)
    }
  }

  @Test func quickAddBatchIntervalDefaultsToTwoSecondsAndClampsFloor() {
    withClearedKey(
      AppAppearancePreference.quickAddBatchWindowKey,
      in: AppAppearancePreference.sharedDefaults
    ) {
      #expect(AppAppearancePreference.quickAddBatchInterval == 2)
    }

    withValue(
      0.1,
      forKey: AppAppearancePreference.quickAddBatchWindowKey,
      in: AppAppearancePreference.sharedDefaults
    ) {
      #expect(AppAppearancePreference.quickAddBatchInterval == 0.5)
    }

    withValue(
      3.0,
      forKey: AppAppearancePreference.quickAddBatchWindowKey,
      in: AppAppearancePreference.sharedDefaults
    ) {
      #expect(AppAppearancePreference.quickAddBatchInterval == 3)
    }
  }

  @Test func resolvedPaletteIndexUsesMonoIndexWhenMonoIsEnabled() {
    let defaults = AppAppearancePreference.sharedDefaults
    withValue(true, forKey: AppAppearancePreference.monoEnabledKey, in: defaults) {
      withValue(4, forKey: AppAppearancePreference.monoPaletteIndexKey, in: defaults) {
        #expect(AppAppearancePreference.resolvedPaletteIndex(9) == 4)
      }
    }

    withValue(false, forKey: AppAppearancePreference.monoEnabledKey, in: defaults) {
      #expect(AppAppearancePreference.resolvedPaletteIndex(9) == 9)
    }
  }

  @Test func batchWindowLabelUsesSingularForOneSecond() {
    #expect(AppAppearancePreference.batchWindowLabel(for: 1) == "1 second")
    #expect(AppAppearancePreference.batchWindowLabel(for: 2) == "2 seconds")
  }
}
