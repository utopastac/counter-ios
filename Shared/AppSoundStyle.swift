import Foundation

/// Global tap-sound feedback style for logging and undo.
nonisolated enum AppSoundStyle: String, Codable, CaseIterable, Identifiable {
  case off
  case soft
  case crisp
  case tap

  var id: String { rawValue }

  var label: String {
    switch self {
    case .off: "Off"
    case .soft: "Soft"
    case .crisp: "Crisp"
    case .tap: "Tap"
    }
  }

  var isEnabled: Bool { self != .off }

  /// System sound IDs for a successful log / add.
  var logSoundID: UInt32? {
    switch self {
    case .off: nil
    case .soft: 1104
    case .crisp: 1057
    case .tap: 1105
    }
  }

  /// System sound IDs for undo / remove.
  var undoSoundID: UInt32? {
    switch self {
    case .off: nil
    case .soft: 1103
    case .crisp: 1053
    case .tap: 1105
    }
  }
}
