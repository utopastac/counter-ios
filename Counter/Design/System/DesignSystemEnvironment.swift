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
}

extension View {
  func counterDesignSystem(_ system: CounterDesignSystem) -> some View {
    environment(\.designSystem, system)
  }

  func counterAccent(_ accent: CounterAccent) -> some View {
    environment(\.counterAccent, accent)
  }

  /// Syncs semantic tokens with the current system light/dark mode.
  func counterDesignSystemFromColorScheme() -> some View {
    modifier(CounterDesignSystemProvider())
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
