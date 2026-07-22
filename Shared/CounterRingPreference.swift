import Foundation

/// Per-counter ring-style picker value. `default` inherits the app-wide setting.
nonisolated enum ProgressRingStyleChoice: String, Codable, CaseIterable, Identifiable, Hashable {
  case `default`
  case solid
  case square
  case hexagon

  var id: String { rawValue }

  var label: String {
    switch self {
    case .default: "Default"
    case .solid: ProgressRingStyle.solid.label
    case .square: ProgressRingStyle.square.label
    case .hexagon: ProgressRingStyle.hexagon.label
    }
  }

  init(storedRaw: String?) {
    // Migrate the old "glow" style case (glow is now a separate toggle).
    if storedRaw == "glow" {
      self = .solid
      return
    }
    if let storedRaw, let choice = Self(rawValue: storedRaw), choice != .default {
      self = choice
    } else {
      self = .default
    }
  }

  /// `nil` means inherit the app setting.
  var storedRaw: String? {
    self == .default ? nil : rawValue
  }
}

/// Per-counter ring-width picker value. `default` inherits the app-wide setting.
nonisolated enum ProgressRingWidthChoice: String, Codable, CaseIterable, Identifiable, Hashable {
  case `default`
  case thin
  case balanced
  case chunky

  var id: String { rawValue }

  var label: String {
    switch self {
    case .default: "Default"
    case .thin: ProgressRingWidth.thin.label
    case .balanced: ProgressRingWidth.balanced.label
    case .chunky: ProgressRingWidth.chunky.label
    }
  }

  init(storedRaw: String?) {
    if let storedRaw, let choice = Self(rawValue: storedRaw), choice != .default {
      self = choice
    } else {
      self = .default
    }
  }

  /// `nil` means inherit the app setting.
  var storedRaw: String? {
    self == .default ? nil : rawValue
  }
}

/// Per-counter ring-glow picker value. `default` inherits the app-wide setting.
nonisolated enum ProgressRingGlowChoice: String, Codable, CaseIterable, Identifiable, Hashable {
  case `default`
  case on
  case off

  var id: String { rawValue }

  var label: String {
    switch self {
    case .default: "Default"
    case .on: "On"
    case .off: "Off"
    }
  }

  init(storedRaw: String?) {
    if let storedRaw, let choice = Self(rawValue: storedRaw), choice != .default {
      self = choice
    } else {
      self = .default
    }
  }

  /// `nil` means inherit the app setting.
  var storedRaw: String? {
    self == .default ? nil : rawValue
  }

  /// Explicit on/off, or `nil` to inherit.
  var overrideEnabled: Bool? {
    switch self {
    case .default: nil
    case .on: true
    case .off: false
    }
  }
}
