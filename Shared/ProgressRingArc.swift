import SwiftUI

/// Shared progress-ring geometry: circle, or a flat-topped regular polygon (square / hex).
///
/// Polygons are drawn as a filled outer/inner ribbon so thick corners stay sharp without
/// stroked-miter artifacts. Circles remain a stroked centerline arc.
nonisolated enum ProgressRingGeometry {
  /// Wraps a continuously-growing `fraction` (e.g. `1.5` for a lap-and-a-half) back into
  /// `(0, 1]` for drawing.
  static func lapFraction(for fraction: Double) -> Double {
    guard fraction > 0 else { return 0 }
    let wrapped = fraction.truncatingRemainder(dividingBy: 1)
    return wrapped == 0 ? 1 : wrapped
  }

  /// Ring path for `fraction` of a lap.
  /// - Circle: stroked centerline arc (inset by `lineWidth / 2`).
  /// - Polygon: filled ribbon between parallel outer/inner polygons.
  static func path(
    fraction: Double,
    in rect: CGRect,
    lineWidth: CGFloat,
    sides: Int?
  ) -> Path {
    let clamped = lapFraction(for: fraction)
    guard clamped > 0 else { return Path() }

    let center = CGPoint(x: rect.midX, y: rect.midY)

    if let sides, sides >= 3 {
      let cosHalf = CGFloat(cos(.pi / Double(sides)))
      let miterOutset = (lineWidth / 2) / max(cosHalf, 0.01)
      let maxRadius = min(rect.width, rect.height) / 2
      let radius = max(maxRadius - miterOutset, lineWidth)
      return polygonRibbonPath(
        fraction: clamped,
        center: center,
        radius: radius,
        sides: sides,
        lineWidth: lineWidth
      )
    }

    let insetRect = rect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
    let radius = min(insetRect.width, insetRect.height) / 2
    return circlePath(fraction: clamped, center: center, radius: radius)
  }

  /// Tip pose at `fraction`: point on the centerline and the travel direction (radians, screen space).
  static func tipPose(
    fraction: Double,
    in rect: CGRect,
    lineWidth: CGFloat,
    sides: Int?
  ) -> (point: CGPoint, travelRadians: CGFloat)? {
    let clamped = lapFraction(for: fraction)
    guard clamped > 0 else { return nil }

    let center = CGPoint(x: rect.midX, y: rect.midY)

    if let sides, sides >= 3 {
      let cosHalf = CGFloat(cos(.pi / Double(sides)))
      let miterOutset = (lineWidth / 2) / max(cosHalf, 0.01)
      let maxRadius = min(rect.width, rect.height) / 2
      let radius = max(maxRadius - miterOutset, lineWidth)
      return polygonTipPose(fraction: clamped, center: center, radius: radius, sides: sides)
    }

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

  // MARK: - Circle

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

  // MARK: - Polygon ribbon

  /// Flat-topped regular polygon vertices, first edge on top (clockwise).
  private static func polygonVertices(sides: Int, center: CGPoint, radius: CGFloat) -> [CGPoint] {
    let startDegrees = -90.0 - (180.0 / Double(sides))
    let step = 360.0 / Double(sides)
    return (0..<sides).map { index in
      let angle = Angle.degrees(startDegrees + step * Double(index)).radians
      return CGPoint(
        x: center.x + radius * cos(angle),
        y: center.y + radius * sin(angle)
      )
    }
  }

  /// Perimeter points starting at the top-edge midpoint, walking clockwise back to start.
  private static func polygonLoopPoints(sides: Int, center: CGPoint, radius: CGFloat) -> [CGPoint] {
    let vertices = polygonVertices(sides: sides, center: center, radius: radius)
    let start = CGPoint(
      x: (vertices[0].x + vertices[1].x) / 2,
      y: (vertices[0].y + vertices[1].y) / 2
    )
    var points: [CGPoint] = [start]
    for index in 1..<sides {
      points.append(vertices[index])
    }
    points.append(vertices[0])
    points.append(start)
    return points
  }

  /// Filled ring segment between parallel outer/inner polygons — avoids stroked miter spikes.
  private static func polygonRibbonPath(
    fraction: Double,
    center: CGPoint,
    radius: CGFloat,
    sides: Int,
    lineWidth: CGFloat
  ) -> Path {
    let cosHalf = CGFloat(cos(.pi / Double(sides)))
    let half = lineWidth / 2
    let outerRadius = radius + half / max(cosHalf, 0.01)
    let innerRadius = max(radius - half / max(cosHalf, 0.01), radius * 0.05)

    let outerLoop = polygonLoopPoints(sides: sides, center: center, radius: outerRadius)
    let innerLoop = polygonLoopPoints(sides: sides, center: center, radius: innerRadius)

    if fraction >= 0.999 {
      return closedRibbon(outer: outerLoop, inner: innerLoop)
    }

    let outerWalk = walkLoop(outerLoop, fraction: fraction)
    let innerWalk = walkLoop(innerLoop, fraction: fraction)
    guard let outerTip = outerWalk.last, let innerTip = innerWalk.last else {
      return Path()
    }

    var path = Path()
    path.move(to: outerWalk[0])
    for point in outerWalk.dropFirst() {
      path.addLine(to: point)
    }
    // Flat tip face across the stroke.
    path.addLine(to: innerTip)
    for point in innerWalk.dropLast().reversed() {
      path.addLine(to: point)
    }
    path.closeSubpath()
    return path
  }

  private static func closedRibbon(outer: [CGPoint], inner: [CGPoint]) -> Path {
    var path = Path()
    guard let outerStart = outer.first, let innerStart = inner.first else { return path }

    path.move(to: outerStart)
    for point in outer.dropFirst() {
      path.addLine(to: point)
    }
    path.addLine(to: innerStart)
    for index in stride(from: inner.count - 2, through: 0, by: -1) {
      path.addLine(to: inner[index])
    }
    path.closeSubpath()
    return path
  }

  private static func walkLoop(_ points: [CGPoint], fraction: Double) -> [CGPoint] {
    let total = perimeterLength(points)
    let target = max(total * fraction, 0.0001)
    var result: [CGPoint] = [points[0]]
    var walked: CGFloat = 0

    for index in 0..<(points.count - 1) {
      let a = points[index]
      let b = points[index + 1]
      let segment = hypot(b.x - a.x, b.y - a.y)
      if walked + segment >= target {
        let t = (target - walked) / max(segment, 0.0001)
        result.append(CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t))
        return result
      }
      result.append(b)
      walked += segment
    }
    return result
  }

  private static func polygonTipPose(
    fraction: Double,
    center: CGPoint,
    radius: CGFloat,
    sides: Int
  ) -> (point: CGPoint, travelRadians: CGFloat) {
    let points = polygonLoopPoints(sides: sides, center: center, radius: radius)
    let total = perimeterLength(points)
    let target = max(total * min(fraction, 0.999999), 0.0001)

    var walked: CGFloat = 0
    for index in 0..<(points.count - 1) {
      let a = points[index]
      let b = points[index + 1]
      let dx = b.x - a.x
      let dy = b.y - a.y
      let segment = hypot(dx, dy)
      if walked + segment >= target {
        let t = (target - walked) / max(segment, 0.0001)
        let point = CGPoint(x: a.x + dx * t, y: a.y + dy * t)
        return (point, atan2(dy, dx))
      }
      walked += segment
    }

    let last = points[points.count - 2]
    let end = points[points.count - 1]
    return (end, atan2(end.y - last.y, end.x - last.x))
  }

  private static func perimeterLength(_ points: [CGPoint]) -> CGFloat {
    var total: CGFloat = 0
    for index in 0..<(points.count - 1) {
      let a = points[index]
      let b = points[index + 1]
      total += hypot(b.x - a.x, b.y - a.y)
    }
    return total
  }
}

/// Arc / polygon segment for a progress ring, starting at 12 o'clock and sweeping clockwise.
///
/// Circles are stroked centerlines; polygons are filled ribbons (`sides != nil`).
nonisolated struct ProgressRingArc: Shape {
  var fraction: Double
  var lineWidth: CGFloat
  /// `nil` draws a circle; otherwise a flat-topped regular polygon with this many sides.
  var sides: Int? = nil

  var animatableData: Double {
    get { fraction }
    set { fraction = newValue }
  }

  /// Polygons are filled ribbons; circles are stroked arcs.
  var usesFill: Bool { sides != nil }

  func path(in rect: CGRect) -> Path {
    ProgressRingGeometry.path(
      fraction: fraction,
      in: rect,
      lineWidth: lineWidth,
      sides: sides
    )
  }
}
