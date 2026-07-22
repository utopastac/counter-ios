import CoreGraphics
import Foundation

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

/// Shared drawing metrics for the optional soft ring glow.
enum ProgressRingGlowMetrics {
  /// Soft bloom applied to the background (track) ring when glow is on.
  static let trackBlurRadius: CGFloat = 10
  /// White highlight layer opacity — kept low so the bloom stays subtle.
  static let highlightOpacity: Double = 0.28
  /// Highlight blur as a fraction of stroke width (masked to the track band).
  static let highlightBlurFactor: CGFloat = 0.35
}
