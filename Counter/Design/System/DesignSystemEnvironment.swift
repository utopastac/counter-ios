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

private struct CounterDesignSystemKey: EnvironmentKey {
  static let defaultValue = CounterDesignSystem(colorScheme: .dark, accent: nil)
}

private struct CounterAccentKey: EnvironmentKey {
  static let defaultValue: CounterAccent? = nil
}

private struct CounterPagerScrollProgressKey: EnvironmentKey {
  static let defaultValue: CGFloat? = nil
}

private struct CounterPagerAccentsKey: EnvironmentKey {
  static let defaultValue: [CounterAccent]? = nil
}

private struct CounterPagerIsDraggingKey: EnvironmentKey {
  static let defaultValue = false
}

private struct CounterRevealIsDraggingKey: EnvironmentKey {
  static let defaultValue = false
}

extension EnvironmentValues {
  var designSystem: CounterDesignSystem {
    get {
      var system = self[CounterDesignSystemKey.self]
      system.accent = counterAccent
      return system
    }
    set { self[CounterDesignSystemKey.self] = newValue }
  }

  var semanticColors: SemanticColors {
    designSystem.colors
  }

  var counterAccent: CounterAccent? {
    get { self[CounterAccentKey.self] }
    set { self[CounterAccentKey.self] = newValue }
  }

  var counterPagerScrollProgress: CGFloat? {
    get { self[CounterPagerScrollProgressKey.self] }
    set { self[CounterPagerScrollProgressKey.self] = newValue }
  }

  var counterPagerAccents: [CounterAccent]? {
    get { self[CounterPagerAccentsKey.self] }
    set { self[CounterPagerAccentsKey.self] = newValue }
  }

  var counterPagerIsDragging: Bool {
    get { self[CounterPagerIsDraggingKey.self] }
    set { self[CounterPagerIsDraggingKey.self] = newValue }
  }

  var counterRevealIsDragging: Bool {
    get { self[CounterRevealIsDraggingKey.self] }
    set { self[CounterRevealIsDraggingKey.self] = newValue }
  }
}

extension View {
  func counterDesignSystem(_ system: CounterDesignSystem) -> some View {
    environment(\.designSystem, system)
  }

  func counterAccent(_ accent: CounterAccent) -> some View {
    environment(\.counterAccent, accent)
  }

  func counterPagerBackground(accents: [CounterAccent], scrollProgress: CGFloat) -> some View {
    environment(\.counterPagerAccents, accents)
      .environment(\.counterPagerScrollProgress, scrollProgress)
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
