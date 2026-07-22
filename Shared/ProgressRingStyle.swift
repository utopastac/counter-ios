import CoreGraphics
import Foundation
import SwiftUI

/// Progress-ring shape style (circle vs polygon). Glow is a separate preference.
nonisolated enum ProgressRingStyle: String, Codable, CaseIterable, Identifiable {
  case solid
  case square
  case hexagon

  var id: String { rawValue }

  var label: String {
    switch self {
    case .solid: "Solid"
    case .square: "Square"
    case .hexagon: "Hexagon"
    }
  }

  /// `nil` draws a circle; 4 / 6 draw flat-topped regular polygons.
  var ringSides: Int? {
    switch self {
    case .solid: nil
    case .square: 4
    case .hexagon: 6
    }
  }

  /// Whether the growing tip cap / cutout rim should be drawn.
  var showsTip: Bool { true }

  /// Flat rectangular tip (polygon rings) vs round tip (circle rings).
  var usesFlatTip: Bool { ringSides != nil }

  func strokeStyle(lineWidth: CGFloat) -> StrokeStyle {
    switch self {
    case .solid:
      return StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
    case .square, .hexagon:
      return StrokeStyle(lineWidth: lineWidth, lineCap: .butt, lineJoin: .miter)
    }
  }
}
