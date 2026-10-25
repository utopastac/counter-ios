import SwiftUI

/// Paper and ink from Doodleoop’s drawing page. The sketch sheet keeps this
/// desk even when Dayring is in dark mode.
enum SketchChrome {
  static let paper = Color(red: 0.961, green: 0.945, blue: 0.910)
  static let paperWhite = Color(red: 0.988, green: 0.980, blue: 0.961)
  static let tan = Color(red: 0.863, green: 0.835, blue: 0.784)
  static let ink = Color(red: 0.098, green: 0.086, blue: 0.071)
  static let gridLine = ink.opacity(0.1)
  static let placeholder = Color(red: 0.765, green: 0.737, blue: 0.698)
  static let dot = Color(red: 0.804, green: 0.776, blue: 0.729)

  static let pageInset: CGFloat = 24
  static let controlRadius: CGFloat = 2
  static let borderThin: CGFloat = 1
  static let borderHeavy: CGFloat = 3
}

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

  var iconName: String {
    switch self {
    case .pen: "SketchIconPenNib"
    case .pencil: "SketchIconPencil"
    case .highlighter: "SketchIconPaintBrush"
    case .eraser: "SketchIconEraser"
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
