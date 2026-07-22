import CoreGraphics
import Foundation

/// Global progress-ring stroke thickness, expressed as a fraction of the ring's outer size.
nonisolated enum ProgressRingWidth: String, Codable, CaseIterable, Identifiable {
  case thin
  case balanced
  case chunky

  var id: String { rawValue }

  var label: String {
    switch self {
    case .thin: "Thin"
    case .balanced: "Balanced"
    case .chunky: "Chunky"
    }
  }

  /// Stroke thickness as a fraction of the ring's outer diameter.
  /// Balanced (`0.25`) matches the original design ratio.
  var ratio: CGFloat {
    switch self {
    case .thin: 0.10
    case .balanced: 0.25
    case .chunky: 0.40
    }
  }

  func strokeWidth(for size: CGFloat) -> CGFloat {
    size * ratio
  }
}
