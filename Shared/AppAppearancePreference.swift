import Foundation

enum AppAppearancePreference {
  static let darkModeEnabledKey = "app.appearance.darkModeEnabled"
  static let hapticsEnabledKey = "app.haptics.enabled"
  static let compactModeEnabledKey = "app.appearance.compactModeEnabled"
  static let defaultResetPeriodKey = "app.defaults.resetPeriod"
  static let monoEnabledKey = "app.appearance.monoEnabled"
  static let monoPaletteIndexKey = "app.appearance.monoPaletteIndex"
  static let quickAddBatchWindowKey = "app.quickAdd.batchWindowSeconds"

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

  static var isCompactModeEnabled: Bool {
    UserDefaults.standard.bool(forKey: compactModeEnabledKey)
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
