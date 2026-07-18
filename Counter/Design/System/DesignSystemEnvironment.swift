import SwiftUI

/// Injected design system context for views.
struct CounterDesignSystem: Equatable {
  var colorScheme: ColorScheme
  var accent: CounterAccent?

  var colors: SemanticColors {
    var resolved = colorScheme.counterSemanticColors
    if let accent {
      resolved = resolved.withCounterTheme(accent.palette, colorScheme: colorScheme)
    }
    return resolved
  }

  static func automatic(colorScheme: ColorScheme) -> CounterDesignSystem {
    CounterDesignSystem(colorScheme: colorScheme, accent: nil)
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
  @Entry var counterPagerIsDragging = false
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

  func counterPagerDragging(_ isDragging: Bool) -> some View {
    environment(\.counterPagerIsDragging, isDragging)
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

  func body(content: Content) -> some View {
    content
      .environment(
        \.designSystem,
        CounterDesignSystem(colorScheme: colorScheme, accent: counterAccent)
      )
  }
}

private struct CounterAppearancePreferenceProvider: ViewModifier {
  @AppStorage(AppAppearancePreference.darkModeEnabledKey) private var isDarkModeEnabled = false

  private var colorScheme: ColorScheme {
    isDarkModeEnabled ? .dark : .light
  }

  func body(content: Content) -> some View {
    content
      .environment(
        \.designSystem,
        CounterDesignSystem(colorScheme: colorScheme, accent: nil)
      )
      .preferredColorScheme(colorScheme)
  }
}
