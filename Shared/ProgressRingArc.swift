import SwiftUI

/// Shared circular progress-ring geometry.
nonisolated enum ProgressRingGeometry {
  /// Wraps a continuously-growing `fraction` (e.g. `1.5` for a lap-and-a-half) back into
  /// `(0, 1]` for drawing.
  static func lapFraction(for fraction: Double) -> Double {
    guard fraction > 0 else { return 0 }
    let wrapped = fraction.truncatingRemainder(dividingBy: 1)
    return wrapped == 0 ? 1 : wrapped
  }

  /// Centerline arc for `fraction` of a lap, inset by `lineWidth / 2`.
  static func path(
    fraction: Double,
    in rect: CGRect,
    lineWidth: CGFloat
  ) -> Path {
    let clamped = lapFraction(for: fraction)
    guard clamped > 0 else { return Path() }

    let center = CGPoint(x: rect.midX, y: rect.midY)
    let insetRect = rect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
    let radius = min(insetRect.width, insetRect.height) / 2
    return circlePath(fraction: clamped, center: center, radius: radius)
  }

  /// Tip pose at `fraction`: point on the centerline and the travel direction (radians, screen space).
  static func tipPose(
    fraction: Double,
    in rect: CGRect,
    lineWidth: CGFloat
  ) -> (point: CGPoint, travelRadians: CGFloat)? {
    let clamped = lapFraction(for: fraction)
    guard clamped > 0 else { return nil }

    let center = CGPoint(x: rect.midX, y: rect.midY)
    let insetRect = rect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
    let radius = min(insetRect.width, insetRect.height) / 2
    let sweepDegrees = clamped >= 0.999 ? 360 - 0.001 : clamped * 360
    let tipAngle = Angle.degrees(-90 + sweepDegrees)
    let theta = tipAngle.radians
    let point = CGPoint(
      x: center.x + radius * cos(theta),
      y: center.y + radius * sin(theta)
    )
    // Clockwise travel is +90° from the outward radial.
    return (point, theta + .pi / 2)
  }

  private static func circlePath(fraction: Double, center: CGPoint, radius: CGFloat) -> Path {
    var path = Path()
    let start = Angle.degrees(-90)
    let end = Angle.degrees(-90 + (fraction * 360))

    if fraction >= 0.999 {
      path.addArc(
        center: center,
        radius: radius,
        startAngle: start,
        endAngle: .degrees(270 - 0.001),
        clockwise: false
      )
    } else {
      path.addArc(
        center: center,
        radius: radius,
        startAngle: start,
        endAngle: end,
        clockwise: false
      )
    }
    return path
  }
}

/// Circular arc for a progress ring, starting at 12 o'clock and sweeping clockwise.
nonisolated struct ProgressRingArc: Shape {
  var fraction: Double
  var lineWidth: CGFloat

  var animatableData: Double {
    get { fraction }
    set { fraction = newValue }
  }

  func path(in rect: CGRect) -> Path {
    ProgressRingGeometry.path(
      fraction: fraction,
      in: rect,
      lineWidth: lineWidth
    )
  }
}
