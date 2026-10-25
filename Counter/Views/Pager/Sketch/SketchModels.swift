import SwiftUI

enum SketchTool: String, CaseIterable, Equatable {
  case pencil
  case pen
  case highlighter
  case eraser

  var displayName: String {
    switch self {
    case .pencil: "Pencil"
    case .pen: "Pen"
    case .highlighter: "Highlighter"
    case .eraser: "Eraser"
    }
  }

  var symbolName: String {
    switch self {
    case .pen: "pencil.tip"
    case .pencil: "pencil"
    case .highlighter: "highlighter"
    case .eraser: "eraser"
    }
  }

  /// Toolbar order matches Doodleoop: pen, pencil, brush, eraser.
  static let toolbarOrder: [SketchTool] = [.pen, .pencil, .highlighter, .eraser]

  var opacity: Double {
    switch self {
    case .pencil: 0.72
    case .pen: 1
    case .highlighter: 0.38
    case .eraser: 1
    }
  }

  var defaultWidth: Double {
    switch self {
    case .pencil: 8
    case .pen: 10
    case .highlighter: 24
    case .eraser: 24
    }
  }

  var availableWidths: [Double] {
    switch self {
    case .pencil: [3, 8, 16, 28]
    case .pen: [4, 10, 18, 32]
    case .highlighter: [14, 24, 40, 56]
    case .eraser: [12, 24, 40, 64]
    }
  }

  var usesFlatTip: Bool { self == .highlighter }
  var isEraser: Bool { self == .eraser }
}

enum SketchPalette {
  static let hexes: [String] = [
    "#FFFFFF",
    "#000000",
    "#6176FF",
    "#56CD38",
    "#EC6363",
    "#EEDB4D",
    "#EF68C8",
    "#EE9048",
  ]

  static let defaultHex = hexes[1]

  static func isLightHex(_ hex: String) -> Bool {
    let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted).uppercased()
    return cleaned == "FFFFFF" || cleaned == "FFFFFFFF"
  }
}

struct SketchPoint: Equatable {
  var x: Double
  var y: Double
  var lineWidth: Double?

  init(x: Double, y: Double, lineWidth: Double? = nil) {
    self.x = x
    self.y = y
    self.lineWidth = lineWidth
  }
}

struct SketchStroke: Equatable, Identifiable {
  var id = UUID()
  var points: [SketchPoint] = []
  var lineWidth: Double = SketchTool.pen.defaultWidth
  var tool: SketchTool = .pen
  var colorHex: String = SketchPalette.defaultHex
}

struct SketchDrawing: Equatable {
  var strokes: [SketchStroke] = []

  static let empty = SketchDrawing()

  var isEmpty: Bool { strokes.isEmpty || strokes.allSatisfy(\.points.isEmpty) }
}

/// Up to 10 reversible actions (stroke commits and clear).
struct SketchUndoStack {
  private enum Step {
    case removeLastStroke
    case restore(SketchDrawing)
  }

  private var steps: [Step] = []
  private let limit = 10

  var canUndo: Bool { !steps.isEmpty }

  mutating func registerStrokeAdded() {
    steps.append(.removeLastStroke)
    trim()
  }

  mutating func registerClear(before drawing: SketchDrawing) {
    guard !drawing.isEmpty else { return }
    steps.append(.restore(drawing))
    trim()
  }

  mutating func undo(drawing: inout SketchDrawing) {
    guard let step = steps.popLast() else { return }
    switch step {
    case .removeLastStroke:
      if !drawing.strokes.isEmpty {
        drawing.strokes.removeLast()
      }
    case .restore(let previous):
      drawing = previous
    }
  }

  private mutating func trim() {
    if steps.count > limit {
      steps.removeFirst(steps.count - limit)
    }
  }
}

/// Finger samples become an in-progress stroke. Close samples are dropped so a fast stroke stays smooth.
struct SketchLiveStroke {
  static let minSpacing: CGFloat = 0.7
  static let endMergeEpsilon = 0.0005

  private(set) var currentStroke: SketchStroke?
  private var lastSampleTime: TimeInterval?
  private var lastSampleLocation: CGPoint?
  private var smoothedPenWidth: Double?

  var isLiveErasing: Bool { currentStroke?.tool.isEraser == true }

  mutating func appendSample(
    at location: CGPoint,
    timestamp: TimeInterval,
    in size: CGSize,
    tool: SketchTool,
    colorHex: String,
    lineWidth: Double
  ) {
    let canvasWidth = max(size.width, 1)
    let canvasHeight = max(size.height, 1)
    let pointWidth = penPointWidth(
      at: location,
      now: timestamp,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
      tool: tool,
      lineWidth: lineWidth
    )
    let point = SketchPoint(
      x: location.x / canvasWidth,
      y: location.y / canvasHeight,
      lineWidth: pointWidth
    )

    if currentStroke == nil {
      currentStroke = SketchStroke(
        points: [point],
        lineWidth: lineWidth,
        tool: tool,
        colorHex: colorHex
      )
      lastSampleTime = timestamp
      lastSampleLocation = location
      smoothedPenWidth = pointWidth
      return
    }

    guard let last = currentStroke?.points.last else { return }
    let dx = (point.x - last.x) * canvasWidth
    let dy = (point.y - last.y) * canvasHeight
    let distance = hypot(dx, dy)

    if distance < Self.minSpacing {
      if tool == .pen, var stroke = currentStroke, !stroke.points.isEmpty {
        stroke.points[stroke.points.count - 1].lineWidth = pointWidth
        currentStroke = stroke
      }
      lastSampleTime = timestamp
      lastSampleLocation = location
      return
    }

    currentStroke?.points.append(point)
    lastSampleTime = timestamp
    lastSampleLocation = location
  }

  mutating func finish(
    at location: CGPoint,
    in size: CGSize,
    tool: SketchTool,
    lineWidth: Double
  ) -> SketchStroke? {
    defer {
      currentStroke = nil
      lastSampleTime = nil
      lastSampleLocation = nil
      smoothedPenWidth = nil
    }

    guard var stroke = currentStroke else { return nil }

    let canvasWidth = max(size.width, 1)
    let canvasHeight = max(size.height, 1)
    let endWidth: Double? = {
      guard tool == .pen else { return nil }
      return max(0.6, smoothedPenWidth ?? lineWidth)
    }()
    let end = SketchPoint(
      x: location.x / canvasWidth,
      y: location.y / canvasHeight,
      lineWidth: endWidth
    )
    if let last = stroke.points.last,
       abs(last.x - end.x) < Self.endMergeEpsilon,
       abs(last.y - end.y) < Self.endMergeEpsilon {
      stroke.points[stroke.points.count - 1].lineWidth = endWidth ?? last.lineWidth
    } else {
      stroke.points.append(end)
    }
    return stroke
  }

  private mutating func penPointWidth(
    at location: CGPoint,
    now: TimeInterval,
    canvasWidth: CGFloat,
    canvasHeight: CGFloat,
    tool: SketchTool,
    lineWidth: Double
  ) -> Double? {
    guard tool == .pen else { return nil }

    let base = lineWidth
    guard let lastTime = lastSampleTime, let lastLocation = lastSampleLocation else {
      return base * 1.15
    }

    let dt = max(now - lastTime, 1.0 / 240.0)
    let dx = location.x - lastLocation.x
    let dy = location.y - lastLocation.y
    let scale = 390 / max(min(canvasWidth, canvasHeight), 1)
    let speed = Double(hypot(dx, dy) * scale) / dt
    let target = SketchStrokeRenderer.penWidth(base: base, speedPointsPerSecond: speed)
    let previous = smoothedPenWidth ?? base
    let blended = previous * 0.72 + target * 0.28
    smoothedPenWidth = blended
    return blended
  }
}

extension Color {
  init(sketchHex hex: String) {
    let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var value: UInt64 = 0
    Scanner(string: cleaned).scanHexInt64(&value)
    let hasAlpha = cleaned.count == 8
    let alpha = hasAlpha ? Double((value & 0xFF00_0000) >> 24) / 255 : 1
    let red = Double((value & 0x00FF_0000) >> 16) / 255
    let green = Double((value & 0x0000_FF00) >> 8) / 255
    let blue = Double(value & 0x0000_00FF) / 255
    self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
  }
}
