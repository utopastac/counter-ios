import SwiftUI

/// Injected design system context for views.
struct CounterDesignSystem: Equatable {
  var colorScheme: ColorScheme
  var accent: CounterAccent?
  /// Mirrored from prefs so environment updates when tint or colour pack changes.
  var isTintEnabled: Bool = true
  var colorPackRaw: String = CounterColorPack.muted.rawValue
  /// Mirrored so typography re-renders when the font pack preference changes.
  var fontPackRaw: String = FontPack.default.rawValue

  var colors: SemanticColors {
    var resolved = colorScheme.counterSemanticColors
    if let accent {
      resolved = resolved.withCounterTheme(accent.palette, colorScheme: colorScheme)
    }
    return resolved
  }

  static func automatic(colorScheme: ColorScheme) -> CounterDesignSystem {
    CounterDesignSystem(
      colorScheme: colorScheme,
      accent: nil,
      isTintEnabled: AppAppearancePreference.isTintEnabled,
      colorPackRaw: AppAppearancePreference.colorPack.rawValue,
      fontPackRaw: AppAppearancePreference.fontPack.rawValue
    )
  }
}

extension EnvironmentValues {
  /// Backing storage for `designSystem`, which layers `counterAccent` on top on read — kept
  /// separate so that layering logic doesn't have to live inside a hand-written
  /// `EnvironmentKey`. `@Entry` (iOS 17+) generates that boilerplate for every other key here.
  @Entry fileprivate var rawDesignSystem = CounterDesignSystem(colorScheme: .dark, accent: nil)

  var designSystem: CounterDesignSystem {
    get {
      var system = rawDesignSystem
      system.accent = counterAccent
      return system
    }
    set { rawDesignSystem = newValue }
  }

  var semanticColors: SemanticColors {
    designSystem.colors
  }

  @Entry var counterAccent: CounterAccent?
  @Entry var counterPagerScrollState: PagerScrollState?
  @Entry var counterPagerAccents: [CounterAccent]?
  @Entry var counterRevealIsDragging = false
}

extension View {
  func counterDesignSystem(_ system: CounterDesignSystem) -> some View {
    environment(\.designSystem, system)
  }

  func counterAccent(_ accent: CounterAccent) -> some View {
    environment(\.counterAccent, accent)
  }

  func counterPagerBackground(accents: [CounterAccent], scrollState: PagerScrollState) -> some View {
    environment(\.counterPagerAccents, accents)
      .environment(\.counterPagerScrollState, scrollState)
  }

  func counterRevealDragging(_ isDragging: Bool) -> some View {
    environment(\.counterRevealIsDragging, isDragging)
  }

  /// Syncs semantic tokens with the current system light/dark mode.
  func counterDesignSystemFromColorScheme() -> some View {
    modifier(CounterDesignSystemProvider())
  }

  /// Syncs semantic tokens with the in-app dark mode preference.
  /// Use on sheets that must update immediately when toggling appearance.
  func counterDesignSystemFromAppearancePreference() -> some View {
    modifier(CounterAppearancePreferenceProvider())
  }
}

private struct CounterDesignSystemProvider: ViewModifier {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.counterAccent) private var counterAccent
  @AppStorage(
    AppAppearancePreference.tintEnabledKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var isTintEnabled = true
  @AppStorage(
    AppAppearancePreference.colorPackKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var colorPackRaw = CounterColorPack.muted.rawValue
  @AppStorage(
    AppAppearancePreference.fontPackKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var fontPackRaw = FontPack.default.rawValue

  func body(content: Content) -> some View {
    content
      .environment(
        \.designSystem,
        CounterDesignSystem(
          colorScheme: colorScheme,
          accent: counterAccent,
          isTintEnabled: isTintEnabled,
          colorPackRaw: colorPackRaw,
          fontPackRaw: fontPackRaw
        )
      )
  }
}

private struct CounterAppearancePreferenceProvider: ViewModifier {
  @AppStorage(AppAppearancePreference.darkModeEnabledKey) private var isDarkModeEnabled = false
  @AppStorage(
    AppAppearancePreference.tintEnabledKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var isTintEnabled = true
  @AppStorage(
    AppAppearancePreference.colorPackKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var colorPackRaw = CounterColorPack.muted.rawValue
  @AppStorage(
    AppAppearancePreference.fontPackKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var fontPackRaw = FontPack.default.rawValue

  private var colorScheme: ColorScheme {
    isDarkModeEnabled ? .dark : .light
  }

  func body(content: Content) -> some View {
    content
      .environment(
        \.designSystem,
        CounterDesignSystem(
          colorScheme: colorScheme,
          accent: nil,
          isTintEnabled: isTintEnabled,
          colorPackRaw: colorPackRaw,
          fontPackRaw: fontPackRaw
        )
      )
      .preferredColorScheme(colorScheme)
  }
}
