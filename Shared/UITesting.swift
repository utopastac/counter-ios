import Foundation

/// Launch-argument helpers for UI tests and App Store screenshot capture.
///
/// Enable with `-UITesting`. Optionally pass `-UITScene <name>` to open a
/// marketing frame without flaky UI navigation:
/// - `01-pager` — Calories hero (list collapsed)
/// - `02-list` — all-counters list revealed
/// - `03-history` — Calories history sheet
/// - `04-compact` — compact card stack
/// - `05-widgets` — Home Screen widget gallery
enum UITesting {
  static let argument = "-UITesting"
  static let sceneArgument = "-UITScene"

  static var isEnabled: Bool {
    ProcessInfo.processInfo.arguments.contains(argument)
  }

  /// Screenshot / UI-test scene name, if provided after `-UITScene`.
  static var scene: String? {
    let args = ProcessInfo.processInfo.arguments
    guard let index = args.firstIndex(of: sceneArgument),
          args.index(after: index) < args.endIndex
    else { return nil }
    let value = args[args.index(after: index)]
    return value.hasPrefix("-") ? nil : value
  }

  static var parsedScene: Scene? {
    scene.flatMap(Scene.init(rawValue:))
  }

  enum Scene: String {
    case pager = "01-pager"
    case list = "02-list"
    case history = "03-history"
    case compact = "04-compact"
    case widgets = "05-widgets"
  }

  /// Quiet prefs + scene-specific appearance before the first frame.
  static func preparePreferences() {
    guard isEnabled else { return }

    FreshInstallOnboarding.markCompleted()
    FreshInstallOnboarding.endPreview()
    UserDefaults.standard.set(false, forKey: AppDataReset.suppressSampleSeedingKey)
    UserDefaults.standard.set(false, forKey: AppAppearancePreference.darkModeEnabledKey)
    UserDefaults.standard.set(false, forKey: AppAppearancePreference.hapticsEnabledKey)
    UserDefaults.standard.set(false, forKey: AppAppearancePreference.fpsCounterEnabledKey)
    UserDefaults.standard.set(
      AppSoundStyle.off.rawValue,
      forKey: AppAppearancePreference.soundStyleKey
    )

    let wantsCompact = parsedScene == .compact
    UserDefaults.standard.set(wantsCompact, forKey: AppAppearancePreference.compactModeEnabledKey)

    AppAppearancePreference.sharedDefaults.set(
      CounterColorPack.muted.rawValue,
      forKey: AppAppearancePreference.colorPackKey
    )
    AppAppearancePreference.sharedDefaults.set(
      false,
      forKey: AppAppearancePreference.monoEnabledKey
    )
    if AppAppearancePreference.sharedDefaults.object(
      forKey: AppAppearancePreference.tintEnabledKey
    ) == nil {
      AppAppearancePreference.sharedDefaults.set(
        true,
        forKey: AppAppearancePreference.tintEnabledKey
      )
    }
  }

  /// Scenes that should land on the Calories counter (list collapsed).
  static var shouldFocusPrimaryCounter: Bool {
    switch parsedScene {
    case .pager, .history, .compact:
      true
    case .list, .widgets, .none:
      false
    }
  }

  /// Full-screen marketing frame that replaces the pager.
  static var showsWidgetGallery: Bool {
    parsedScene == .widgets
  }
}
