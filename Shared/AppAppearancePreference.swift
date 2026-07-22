import Foundation

enum AppAppearancePreference {
  static let darkModeEnabledKey = "app.appearance.darkModeEnabled"
  static let hapticsEnabledKey = "app.haptics.enabled"
  static let compactModeEnabledKey = "app.appearance.compactModeEnabled"
  static let defaultResetPeriodKey = "app.defaults.resetPeriod"
  static let monoEnabledKey = "app.appearance.monoEnabled"
  static let monoPaletteIndexKey = "app.appearance.monoPaletteIndex"
  static let tintEnabledKey = "app.appearance.tintEnabled"
  static let colorPackKey = "app.appearance.colorPack"
  static let progressRingWidthKey = "app.appearance.progressRingWidth"
  static let progressRingStyleKey = "app.appearance.progressRingStyle"
  static let progressRingGlowEnabledKey = "app.appearance.progressRingGlowEnabled"
  static let fontPackKey = "app.appearance.fontPack"
  static let soundStyleKey = "app.sound.style"
  static let quickAddBatchWindowKey = "app.quickAdd.batchWindowSeconds"
  static let fpsCounterEnabledKey = "app.debug.fpsCounterEnabled"

  /// Shared across the app, widgets, and watch for prefs that affect other processes.
  static let sharedDefaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard

  static let defaultBatchWindowSeconds: Double = 2
  static let batchWindowOptions: [Double] = [1, 2, 3, 5]

  static var isHapticsEnabled: Bool {
    if UserDefaults.standard.object(forKey: hapticsEnabledKey) == nil {
      return true
    }
    return UserDefaults.standard.bool(forKey: hapticsEnabledKey)
  }

  static var defaultResetPeriod: CounterResetPeriod {
    let raw = UserDefaults.standard.string(forKey: defaultResetPeriodKey)
      ?? CounterResetPeriod.daily.rawValue
    return CounterResetPeriod(rawValue: raw) ?? .daily
  }

  static var isMonoEnabled: Bool {
    sharedDefaults.bool(forKey: monoEnabledKey)
  }

  /// When on, counter content uses the opposite-scheme palette colour
  /// (dark background in light mode / light background in dark mode)
  /// instead of black / white. Defaults to on.
  static var isTintEnabled: Bool {
    if sharedDefaults.object(forKey: tintEnabledKey) == nil {
      return true
    }
    return sharedDefaults.bool(forKey: tintEnabledKey)
  }

  static var colorPack: CounterColorPack {
    let raw = sharedDefaults.string(forKey: colorPackKey) ?? CounterColorPack.muted.rawValue
    return CounterColorPack(rawValue: raw) ?? .muted
  }

  /// Stroke thickness for progress rings. Defaults to balanced (25% of ring size).
  static var progressRingWidth: ProgressRingWidth {
    let raw = sharedDefaults.string(forKey: progressRingWidthKey)
      ?? ProgressRingWidth.balanced.rawValue
    return ProgressRingWidth(rawValue: raw) ?? .balanced
  }

  /// Stroke style for progress rings. Defaults to solid (circle, round caps + tip cutout).
  static var progressRingStyle: ProgressRingStyle {
    let raw = sharedDefaults.string(forKey: progressRingStyleKey)
      ?? ProgressRingStyle.solid.rawValue
    // Migrate the retired "glow" style case to solid.
    if raw == "glow" { return .solid }
    return ProgressRingStyle(rawValue: raw) ?? .solid
  }

  /// Soft inner glow on the track (background) ring. Defaults to off.
  static var isProgressRingGlowEnabled: Bool {
    sharedDefaults.bool(forKey: progressRingGlowEnabledKey)
  }

  /// Typeface pack for the app type ramp. Defaults to Default (system sans).
  static var fontPack: FontPack {
    let raw = sharedDefaults.string(forKey: fontPackKey) ?? FontPack.default.rawValue
    return FontPack(rawValue: raw) ?? .default
  }

  /// Tap sounds for logging / undo. Defaults to off.
  static var soundStyle: AppSoundStyle {
    let raw = UserDefaults.standard.string(forKey: soundStyleKey)
      ?? AppSoundStyle.off.rawValue
    return AppSoundStyle(rawValue: raw) ?? .off
  }

  static var isCompactModeEnabled: Bool {
    UserDefaults.standard.bool(forKey: compactModeEnabledKey)
  }

  static var isFPSCounterEnabled: Bool {
    UserDefaults.standard.bool(forKey: fpsCounterEnabledKey)
  }

  static var monoPaletteIndex: Int {
    CustomCounter.normalizedPaletteIndex(
      sharedDefaults.object(forKey: monoPaletteIndexKey) as? Int ?? 0
    )
  }

  static var quickAddBatchInterval: TimeInterval {
    let value = sharedDefaults.object(forKey: quickAddBatchWindowKey) as? Double
      ?? defaultBatchWindowSeconds
    return max(0.5, value)
  }

  static func resolvedPaletteIndex(_ counterPaletteIndex: Int) -> Int {
    if isMonoEnabled {
      return monoPaletteIndex
    }
    return CustomCounter.normalizedPaletteIndex(counterPaletteIndex)
  }

  static func batchWindowLabel(for seconds: Double) -> String {
    seconds == 1 ? "1 second" : "\(Int(seconds)) seconds"
  }
}
