import SwiftUI
import UIKit

enum SketchStrokeRenderer {
  static func canvasPoints(for stroke: SketchStroke, size: CGSize) -> [CGPoint] {
    stroke.points.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }
  }

  /// Slow strokes thicken; fast strokes thin. Speed is points per second on the canvas.
  static func penWidth(base: Double, speedPointsPerSecond: Double) -> Double {
    let minFactor = 0.32
    let maxFactor = 1.65
    let capped = min(max(speedPointsPerSecond, 0), 1600)
    let t = capped / 1600
    let eased = t * t * (3 - 2 * t)
    return max(0.6, base * (maxFactor - (maxFactor - minFactor) * eased))
  }

  static func smoothPath(from points: [CGPoint]) -> Path {
    var path = Path()
    guard let first = points.first else { return path }

    if points.count == 1 {
      path.addEllipse(in: CGRect(x: first.x - 0.5, y: first.y - 0.5, width: 1, height: 1))
      return path
    }

    if points.count == 2 {
      path.move(to: first)
      path.addLine(to: points[1])
      return path
    }

    path.move(to: first)
    for index in 0..<(points.count - 1) {
      let p0 = points[max(index - 1, 0)]
      let p1 = points[index]
      let p2 = points[index + 1]
      let p3 = points[min(index + 2, points.count - 1)]
      let c1 = CGPoint(
        x: p1.x + (p2.x - p0.x) / 6,
        y: p1.y + (p2.y - p0.y) / 6
      )
      let c2 = CGPoint(
        x: p2.x - (p3.x - p1.x) / 6,
        y: p2.y - (p3.y - p1.y) / 6
      )
      path.addCurve(to: p2, control1: c1, control2: c2)
    }
    return path
  }

  static func draw(
    _ stroke: SketchStroke,
    in context: inout GraphicsContext,
    size: CGSize,
    live: Bool = false
  ) {
    let points = canvasPoints(for: stroke, size: size)
    guard !points.isEmpty else { return }

    let width = max(0.8, stroke.lineWidth)
    let color = Color(sketchHex: stroke.colorHex).opacity(stroke.tool.opacity)
    let path = smoothPath(from: points)
    let cap: CGLineCap = stroke.tool.usesFlatTip ? .square : .round
    let style = StrokeStyle(lineWidth: width, lineCap: cap, lineJoin: .round)

    switch stroke.tool {
    case .pen:
      let widths: [CGFloat] = stroke.points.map { point in
        CGFloat(max(0.6, point.lineWidth ?? stroke.lineWidth))
      }
      let ribbon = variableWidthRibbon(points: points, widths: widths, live: live)
      let fillStyle = FillStyle(eoFill: false, antialiased: true)
      context.fill(ribbon.body, with: .color(color), style: fillStyle)
      if let startCap = ribbon.startCap {
        context.fill(Path(ellipseIn: startCap), with: .color(color), style: fillStyle)
      }
      if let endCap = ribbon.endCap {
        context.fill(Path(ellipseIn: endCap), with: .color(color), style: fillStyle)
      }

    case .pencil:
      context.drawLayer { layer in
        layer.addFilter(.blur(radius: max(0.4, width * 0.18)))
        layer.stroke(
          path,
          with: .color(color.opacity(0.55)),
          style: StrokeStyle(lineWidth: width * 1.15, lineCap: .round, lineJoin: .round)
        )
      }
      context.stroke(
        path,
        with: .color(color),
        style: StrokeStyle(lineWidth: width * 0.85, lineCap: .round, lineJoin: .round)
      )

    case .highlighter:
      context.blendMode = .multiply
      context.stroke(path, with: .color(color), style: style)
      context.blendMode = .normal

    case .eraser:
      context.blendMode = .destinationOut
      context.stroke(path, with: .color(.black), style: style)
      context.blendMode = .normal
    }
  }

  static func drawDrawing(
    _ drawing: SketchDrawing,
    liveStroke: SketchStroke? = nil,
    in context: inout GraphicsContext,
    size: CGSize
  ) {
    for stroke in drawing.strokes {
      draw(stroke, in: &context, size: size, live: false)
    }
    if let liveStroke {
      draw(liveStroke, in: &context, size: size, live: true)
    }
  }

  @MainActor
  static func pngData(
    of drawing: SketchDrawing,
    size: CGSize,
    scale: CGFloat,
    background: Color = .white
  ) -> Data? {
    guard !drawing.isEmpty else { return nil }
    let resolved = size.width > 1 && size.height > 1
      ? size
      : CGSize(width: 320, height: 320)
    guard let image = bake(drawing, size: resolved, scale: max(scale, 1), background: background) else {
      return nil
    }
    return image.pngData()
  }

  @MainActor
  static func bake(
    _ drawing: SketchDrawing,
    size: CGSize,
    scale: CGFloat,
    background: Color = .white
  ) -> UIImage? {
    guard size.width > 1, size.height > 1 else { return nil }
    let content = ZStack {
      background
      Canvas { context, canvasSize in
        drawDrawing(drawing, in: &context, size: canvasSize)
      }
    }
    .frame(width: size.width, height: size.height)

    let renderer = ImageRenderer(content: content)
    renderer.scale = scale
    return renderer.uiImage
  }

  private static func catmullRom(
    _ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ t: CGFloat
  ) -> CGPoint {
    CGPoint(
      x: catmullRom(p0.x, p1.x, p2.x, p3.x, t),
      y: catmullRom(p0.y, p1.y, p2.y, p3.y, t)
    )
  }

  private static func catmullRom(
    _ w0: CGFloat, _ w1: CGFloat, _ w2: CGFloat, _ w3: CGFloat, _ t: CGFloat
  ) -> CGFloat {
    let t2: CGFloat = t * t
    let t3: CGFloat = t2 * t
    let a: CGFloat = 2 * w1
    let b: CGFloat = (w2 - w0) * t
    let c: CGFloat = ((2 * w0) - (5 * w1) + (4 * w2) - w3) * t2
    let d: CGFloat = ((3 * w1) - w0 - (3 * w2) + w3) * t3
    return 0.5 * (a + b + c + d)
  }

  private static func chaikin(
    points: [CGPoint],
    widths: [CGFloat],
    iterations: Int
  ) -> (points: [CGPoint], widths: [CGFloat]) {
    var pts = points
    var wds = widths
    guard pts.count >= 3, pts.count == wds.count, iterations > 0 else { return (pts, wds) }

    for _ in 0..<iterations {
      var nextPts: [CGPoint] = [pts[0]]
      var nextWds: [CGFloat] = [wds[0]]
      for index in 0..<(pts.count - 1) {
        let p = pts[index]
        let q = pts[index + 1]
        let wp = wds[index]
        let wq = wds[index + 1]
        nextPts.append(CGPoint(x: 0.75 * p.x + 0.25 * q.x, y: 0.75 * p.y + 0.25 * q.y))
        nextWds.append(0.75 * wp + 0.25 * wq)
        nextPts.append(CGPoint(x: 0.25 * p.x + 0.75 * q.x, y: 0.25 * p.y + 0.75 * q.y))
        nextWds.append(0.25 * wp + 0.75 * wq)
      }
      nextPts.append(pts[pts.count - 1])
      nextWds.append(wds[wds.count - 1])
      pts = nextPts
      wds = nextWds
    }
    return (pts, wds)
  }

  private static func resampledStroke(
    points: [CGPoint],
    widths: [CGFloat],
    spacing: CGFloat,
    chaikinIterations: Int
  ) -> (points: [CGPoint], widths: [CGFloat]) {
    guard points.count >= 2, points.count == widths.count else {
      return (points, widths)
    }

    let smoothed = chaikin(points: points, widths: widths, iterations: chaikinIterations)
    var outPoints: [CGPoint] = [smoothed.points[0]]
    var outWidths: [CGFloat] = [smoothed.widths[0]]

    for index in 0..<(smoothed.points.count - 1) {
      let p0 = smoothed.points[max(index - 1, 0)]
      let p1 = smoothed.points[index]
      let p2 = smoothed.points[index + 1]
      let p3 = smoothed.points[min(index + 2, smoothed.points.count - 1)]
      let w0 = smoothed.widths[max(index - 1, 0)]
      let w1 = smoothed.widths[index]
      let w2 = smoothed.widths[index + 1]
      let w3 = smoothed.widths[min(index + 2, smoothed.widths.count - 1)]

      let segmentLength = hypot(p2.x - p1.x, p2.y - p1.y)
      let steps = max(1, Int(ceil(segmentLength / max(spacing, 0.5))))

      for step in 1...steps {
        let t = CGFloat(step) / CGFloat(steps)
        outPoints.append(catmullRom(p0, p1, p2, p3, t))
        outWidths.append(max(0.5, catmullRom(w0, w1, w2, w3, t)))
      }
    }

    return (outPoints, outWidths)
  }

  private struct PenRibbon {
    var body: Path
    var startCap: CGRect?
    var endCap: CGRect?
  }

  private static func variableWidthRibbon(
    points: [CGPoint],
    widths: [CGFloat],
    live: Bool
  ) -> PenRibbon {
    guard !points.isEmpty else { return PenRibbon(body: Path()) }

    if points.count == 1 {
      let radius = max(0.4, widths[0] / 2)
      let rect = CGRect(
        x: points[0].x - radius, y: points[0].y - radius, width: radius * 2, height: radius * 2
      )
      return PenRibbon(body: Path(ellipseIn: rect))
    }

    let spacing: CGFloat = live ? 2.8 : 1.4
    let sampled = resampledStroke(
      points: points,
      widths: widths,
      spacing: spacing,
      chaikinIterations: live ? 1 : 2
    )
    let pts = sampled.points
    let wds = sampled.widths
    guard pts.count >= 2 else { return PenRibbon(body: Path()) }

    var left: [CGPoint] = []
    var right: [CGPoint] = []
    left.reserveCapacity(pts.count)
    right.reserveCapacity(pts.count)

    for index in pts.indices {
      let tangent: CGPoint
      if index == 0 {
        tangent = CGPoint(x: pts[1].x - pts[0].x, y: pts[1].y - pts[0].y)
      } else if index == pts.count - 1 {
        tangent = CGPoint(x: pts[index].x - pts[index - 1].x, y: pts[index].y - pts[index - 1].y)
      } else {
        tangent = CGPoint(x: pts[index + 1].x - pts[index - 1].x, y: pts[index + 1].y - pts[index - 1].y)
      }

      let length = hypot(tangent.x, tangent.y)
      let nx: CGFloat
      let ny: CGFloat
      if length < 0.001 {
        nx = 0
        ny = 1
      } else {
        nx = -tangent.y / length
        ny = tangent.x / length
      }

      let radius = max(0.35, wds[index] / 2)
      left.append(CGPoint(x: pts[index].x + nx * radius, y: pts[index].y + ny * radius))
      right.append(CGPoint(x: pts[index].x - nx * radius, y: pts[index].y - ny * radius))
    }

    var body = Path()
    body.move(to: left[0])
    for point in left.dropFirst() {
      body.addLine(to: point)
    }
    body.addLine(to: right[right.count - 1])
    for point in right.dropLast().reversed() {
      body.addLine(to: point)
    }
    body.closeSubpath()

    let startRadius = max(0.35, wds[0] / 2)
    let endRadius = max(0.35, wds[wds.count - 1] / 2)
    let start = pts[0]
    let end = pts[pts.count - 1]

    return PenRibbon(
      body: body,
      startCap: CGRect(
        x: start.x - startRadius, y: start.y - startRadius, width: startRadius * 2, height: startRadius * 2
      ),
      endCap: CGRect(
        x: end.x - endRadius, y: end.y - endRadius, width: endRadius * 2, height: endRadius * 2
      )
    )
  }
}
