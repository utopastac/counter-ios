import CoreGraphics
import SwiftUI
import Testing
import UIKit

@MainActor
struct SketchDrawingTests {
  private let canvasSize = CGSize(width: 390, height: 390)

  @Test func toolsMatchDoodleoopBrushes() {
    #expect(SketchTool.toolbarOrder == [.pen, .pencil, .highlighter, .eraser])
    #expect(Set(SketchTool.toolbarOrder) == Set(SketchTool.allCases))

    #expect(SketchTool.pen.symbolName == "pencil.tip")
    #expect(SketchTool.pencil.symbolName == "pencil")
    #expect(SketchTool.highlighter.symbolName == "highlighter")
    #expect(SketchTool.eraser.symbolName == "eraser")

    #expect(SketchTool.pencil.displayName == "Pencil")
    #expect(SketchTool.pen.displayName == "Pen")
    #expect(SketchTool.highlighter.displayName == "Highlighter")
    #expect(SketchTool.eraser.displayName == "Eraser")

    #expect(abs(SketchTool.pencil.opacity - 0.72) < 0.0001)
    #expect(abs(SketchTool.pen.opacity - 1) < 0.0001)
    #expect(abs(SketchTool.highlighter.opacity - 0.38) < 0.0001)
    #expect(SketchTool.highlighter.usesFlatTip)
    #expect(!SketchTool.pen.usesFlatTip)
    #expect(SketchTool.eraser.isEraser)
    #expect(!SketchTool.pen.isEraser)

    #expect(SketchTool.pencil.availableWidths == [3, 8, 16, 28])
    #expect(SketchTool.pen.availableWidths == [4, 10, 18, 32])
    #expect(SketchTool.highlighter.availableWidths == [14, 24, 40, 56])
    #expect(SketchTool.eraser.availableWidths == [12, 24, 40, 64])

    for tool in SketchTool.allCases {
      #expect(tool.availableWidths.contains(tool.defaultWidth))
      #expect(tool.availableWidths.count == 4)
      #expect(tool.availableWidths == tool.availableWidths.sorted())
    }
  }

  @Test func paletteDefaultsToBlackAndMarksWhite() {
    #expect(SketchPalette.hexes.count == 8)
    #expect(SketchPalette.defaultHex == "#000000")
    #expect(SketchPalette.hexes[1] == SketchPalette.defaultHex)
    #expect(SketchPalette.hexes.contains("#FFFFFF"))
    #expect(Set(SketchPalette.hexes).count == SketchPalette.hexes.count)

    #expect(SketchPalette.isLightHex("#FFFFFF"))
    #expect(SketchPalette.isLightHex("#ffffffff"))
    #expect(SketchPalette.isLightHex("FFFFFF"))
    #expect(!SketchPalette.isLightHex("#000000"))
    #expect(!SketchPalette.isLightHex("#6176FF"))
  }

  @Test func sketchHexParsesRGBAndRGBA() {
    let black = UIColor(Color(sketchHex: "#000000"))
    var red: CGFloat = -1
    var green: CGFloat = -1
    var blue: CGFloat = -1
    var alpha: CGFloat = -1
    #expect(black.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
    #expect(abs(red) < 0.001)
    #expect(abs(green) < 0.001)
    #expect(abs(blue) < 0.001)
    #expect(abs(alpha - 1) < 0.001)

    let swatch = UIColor(Color(sketchHex: "#6176FF"))
    #expect(swatch.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
    #expect(abs(red - (0x61 / 255)) < 0.001)
    #expect(abs(green - (0x76 / 255)) < 0.001)
    #expect(abs(blue - (0xFF / 255)) < 0.001)

    let translucent = UIColor(Color(sketchHex: "#80FF0000"))
    #expect(translucent.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
    #expect(abs(alpha - (0x80 / 255)) < 0.001)
    #expect(abs(red - 1) < 0.001)
    #expect(abs(green) < 0.001)
    #expect(abs(blue) < 0.001)
  }

  @Test func undoRemovesStrokesAndRestoresAClear() {
    var stack = SketchUndoStack()
    var drawing = SketchDrawing.empty
    #expect(!stack.canUndo)

    drawing.strokes.append(SketchStroke(points: [SketchPoint(x: 0.1, y: 0.1)]))
    stack.registerStrokeAdded()
    drawing.strokes.append(SketchStroke(points: [SketchPoint(x: 0.9, y: 0.9)]))
    stack.registerStrokeAdded()

    stack.undo(drawing: &drawing)
    #expect(drawing.strokes.count == 1)
    #expect(abs(drawing.strokes[0].points[0].x - 0.1) < 0.0001)

    stack.undo(drawing: &drawing)
    #expect(drawing.isEmpty)
    #expect(!stack.canUndo)

    stack.undo(drawing: &drawing)
    #expect(drawing.isEmpty)
  }

  @Test func undoRestoresTheDrawingClearedFromTheCanvas() {
    var stack = SketchUndoStack()
    var drawing = SketchDrawing(strokes: [
      SketchStroke(points: [SketchPoint(x: 0.2, y: 0.3)]),
      SketchStroke(points: [SketchPoint(x: 0.4, y: 0.5)]),
    ])
    let snapshot = drawing

    stack.registerClear(before: drawing)
    drawing = .empty
    #expect(stack.canUndo)

    stack.undo(drawing: &drawing)
    #expect(drawing == snapshot)
    #expect(!stack.canUndo)
  }

  @Test func clearOfAnEmptyDrawingIsNotUndoable() {
    var stack = SketchUndoStack()
    stack.registerClear(before: .empty)
    #expect(!stack.canUndo)

    stack.registerClear(before: SketchDrawing(strokes: [SketchStroke(points: [])]))
    #expect(!stack.canUndo)
  }

  @Test func undoStackKeepsTheLatestTenSteps() {
    var stack = SketchUndoStack()
    var drawing = SketchDrawing.empty

    for index in 0..<12 {
      drawing.strokes.append(SketchStroke(points: [SketchPoint(x: Double(index), y: 0)]))
      stack.registerStrokeAdded()
    }

    for _ in 0..<10 {
      stack.undo(drawing: &drawing)
    }
    #expect(!stack.canUndo)
    #expect(drawing.strokes.count == 2)
  }

  @Test func liveStrokeNormalizesTheFirstSample() throws {
    var session = SketchLiveStroke()
    session.appendSample(
      at: CGPoint(x: 39, y: 78),
      timestamp: 1,
      in: canvasSize,
      tool: .pencil,
      colorHex: "#EC6363",
      lineWidth: 16
    )

    let stroke = try #require(session.currentStroke)
    #expect(stroke.tool == .pencil)
    #expect(stroke.colorHex == "#EC6363")
    #expect(stroke.lineWidth == 16)
    #expect(stroke.points.count == 1)
    #expect(abs(stroke.points[0].x - 0.1) < 0.0001)
    #expect(abs(stroke.points[0].y - 0.2) < 0.0001)
    #expect(stroke.points[0].lineWidth == nil)
    #expect(!session.isLiveErasing)
  }

  @Test func penStartsThickAndThinsWhenTheFingerMovesFast() throws {
    var session = SketchLiveStroke()
    session.appendSample(
      at: .zero,
      timestamp: 0,
      in: canvasSize,
      tool: .pen,
      colorHex: SketchPalette.defaultHex,
      lineWidth: 10
    )
    let startWidth = try #require(session.currentStroke?.points.first?.lineWidth)
    #expect(abs(startWidth - 11.5) < 0.0001)

    session.appendSample(
      at: CGPoint(x: 120, y: 0),
      timestamp: 0.01,
      in: canvasSize,
      tool: .pen,
      colorHex: SketchPalette.defaultHex,
      lineWidth: 10
    )
    let fastWidth = try #require(session.currentStroke?.points.last?.lineWidth)
    #expect(fastWidth < startWidth)
  }

  @Test func samplesCloserThanTheMinimumSpacingAreDropped() throws {
    var session = SketchLiveStroke()
    session.appendSample(
      at: .zero,
      timestamp: 0,
      in: canvasSize,
      tool: .highlighter,
      colorHex: "#EEDB4D",
      lineWidth: 24
    )
    session.appendSample(
      at: CGPoint(x: 0.5, y: 0),
      timestamp: 0.01,
      in: canvasSize,
      tool: .highlighter,
      colorHex: "#EEDB4D",
      lineWidth: 24
    )
    #expect(session.currentStroke?.points.count == 1)

    session.appendSample(
      at: CGPoint(x: 8, y: 0),
      timestamp: 0.02,
      in: canvasSize,
      tool: .highlighter,
      colorHex: "#EEDB4D",
      lineWidth: 24
    )
    #expect(session.currentStroke?.points.count == 2)
  }

  @Test func penRefreshesWidthWhenASampleIsTooCloseToAppend() throws {
    var session = SketchLiveStroke()
    session.appendSample(
      at: .zero,
      timestamp: 0,
      in: canvasSize,
      tool: .pen,
      colorHex: SketchPalette.defaultHex,
      lineWidth: 10
    )
    let firstWidth = try #require(session.currentStroke?.points.first?.lineWidth)

    session.appendSample(
      at: CGPoint(x: 0.4, y: 0),
      timestamp: 0.001,
      in: canvasSize,
      tool: .pen,
      colorHex: SketchPalette.defaultHex,
      lineWidth: 10
    )
    #expect(session.currentStroke?.points.count == 1)
    let updated = try #require(session.currentStroke?.points.first?.lineWidth)
    #expect(abs(updated - firstWidth) > 0.0001)
  }

  @Test func finishMergesANearDuplicateEndAndClearsTheLiveStroke() throws {
    var session = SketchLiveStroke()
    session.appendSample(
      at: CGPoint(x: 100, y: 100),
      timestamp: 0,
      in: canvasSize,
      tool: .pen,
      colorHex: SketchPalette.defaultHex,
      lineWidth: 10
    )
    session.appendSample(
      at: CGPoint(x: 140, y: 100),
      timestamp: 0.05,
      in: canvasSize,
      tool: .pen,
      colorHex: SketchPalette.defaultHex,
      lineWidth: 10
    )

    let finished = session.finish(
      at: CGPoint(x: 140.05, y: 100),
      in: canvasSize,
      tool: .pen,
      lineWidth: 10
    )
    let stroke = try #require(finished)
    #expect(stroke.points.count == 2)
    #expect(stroke.points.last?.lineWidth != nil)
    #expect(session.currentStroke == nil)
  }

  @Test func finishAppendsADistinctEraserEnd() throws {
    var session = SketchLiveStroke()
    session.appendSample(
      at: .zero,
      timestamp: 0,
      in: canvasSize,
      tool: .eraser,
      colorHex: "#000000",
      lineWidth: 24
    )
    #expect(session.isLiveErasing)

    let finished = session.finish(
      at: CGPoint(x: 50, y: 60),
      in: canvasSize,
      tool: .eraser,
      lineWidth: 24
    )
    let stroke = try #require(finished)
    #expect(stroke.points.count == 2)
    #expect(stroke.tool == .eraser)
    #expect(stroke.points.last?.lineWidth == nil)
    #expect(!session.isLiveErasing)
  }

  @Test func finishWithNoSamplesReturnsNil() {
    var session = SketchLiveStroke()
    let finished = session.finish(at: .zero, in: canvasSize, tool: .pen, lineWidth: 10)
    #expect(finished == nil)
  }

  @Test func zeroCanvasSizeStillNormalizesAgainstOnePoint() throws {
    var session = SketchLiveStroke()
    session.appendSample(
      at: CGPoint(x: 0.5, y: 0.5),
      timestamp: 0,
      in: .zero,
      tool: .pen,
      colorHex: SketchPalette.defaultHex,
      lineWidth: 10
    )
    let stroke = try #require(session.currentStroke)
    #expect(abs(stroke.points[0].x - 0.5) < 0.0001)
    #expect(abs(stroke.points[0].y - 0.5) < 0.0001)
  }

  @Test func canvasPointsScaleNormalizedCoordinates() {
    let stroke = SketchStroke(points: [
      SketchPoint(x: 0, y: 0),
      SketchPoint(x: 0.5, y: 1),
      SketchPoint(x: 1, y: 0.25),
    ])
    let points = SketchStrokeRenderer.canvasPoints(for: stroke, size: CGSize(width: 200, height: 400))
    #expect(points.count == 3)
    #expect(points[0] == .zero)
    #expect(abs(points[1].x - 100) < 0.001)
    #expect(abs(points[1].y - 400) < 0.001)
    #expect(abs(points[2].x - 200) < 0.001)
    #expect(abs(points[2].y - 100) < 0.001)
  }

  @Test func penWidthIsThickerWhenSlowAndThinnerWhenFast() {
    let base = 10.0
    let slow = SketchStrokeRenderer.penWidth(base: base, speedPointsPerSecond: 0)
    let mid = SketchStrokeRenderer.penWidth(base: base, speedPointsPerSecond: 800)
    let fast = SketchStrokeRenderer.penWidth(base: base, speedPointsPerSecond: 1600)
    let clamped = SketchStrokeRenderer.penWidth(base: base, speedPointsPerSecond: 10_000)
    let negative = SketchStrokeRenderer.penWidth(base: base, speedPointsPerSecond: -50)

    #expect(slow > mid)
    #expect(mid > fast)
    #expect(abs(fast - clamped) < 0.0001)
    #expect(abs(slow - negative) < 0.0001)
    #expect(abs(slow - (base * 1.65)) < 0.0001)
    #expect(abs(fast - max(0.6, base * 0.32)) < 0.0001)
    #expect(SketchStrokeRenderer.penWidth(base: 0.1, speedPointsPerSecond: 1600) >= 0.6)
  }

  @Test func smoothPathHandlesEmptySinglePairAndCurve() {
    #expect(SketchStrokeRenderer.smoothPath(from: []).isEmpty)

    let single = SketchStrokeRenderer.smoothPath(from: [CGPoint(x: 10, y: 20)])
    #expect(!single.isEmpty)

    let pair = SketchStrokeRenderer.smoothPath(from: [
      CGPoint(x: 0, y: 0),
      CGPoint(x: 40, y: 0),
    ])
    #expect(!pair.isEmpty)
    #expect(abs(pair.boundingRect.width - 40) < 0.001)

    let curve = SketchStrokeRenderer.smoothPath(from: [
      CGPoint(x: 0, y: 0),
      CGPoint(x: 20, y: 40),
      CGPoint(x: 40, y: 0),
      CGPoint(x: 60, y: 40),
    ])
    #expect(!curve.isEmpty)
    #expect(curve.boundingRect.width > 0)
  }

  @Test func emptyDrawingDoesNotExportAndInkDoes() {
    #expect(SketchDrawing.empty.isEmpty)
    #expect(SketchDrawing(strokes: [SketchStroke(points: [])]).isEmpty)
    #expect(
      SketchStrokeRenderer.pngData(of: .empty, size: CGSize(width: 120, height: 120), scale: 2) == nil
    )

    let drawing = SketchDrawing(strokes: [
      SketchStroke(
        points: [
          SketchPoint(x: 0.1, y: 0.1, lineWidth: 12),
          SketchPoint(x: 0.8, y: 0.7, lineWidth: 8),
        ],
        lineWidth: SketchTool.pen.defaultWidth,
        tool: .pen,
        colorHex: "#000000"
      ),
    ])
    #expect(!drawing.isEmpty)

    let data = SketchStrokeRenderer.pngData(
      of: drawing,
      size: CGSize(width: 120, height: 120),
      scale: 2
    )
    #expect(data?.isEmpty == false)

    let fallback = SketchStrokeRenderer.pngData(of: drawing, size: .zero, scale: 2)
    #expect(fallback?.isEmpty == false)

    #expect(SketchStrokeRenderer.bake(drawing, size: CGSize(width: 1, height: 100), scale: 1) == nil)
  }

  @Test func eachToolBakesToAnImage() {
    for tool in SketchTool.allCases {
      let drawing = SketchDrawing(strokes: [
        SketchStroke(
          points: [
            SketchPoint(x: 0.2, y: 0.2, lineWidth: tool == .pen ? 14 : nil),
            SketchPoint(x: 0.8, y: 0.6, lineWidth: tool == .pen ? 8 : nil),
          ],
          lineWidth: tool.defaultWidth,
          tool: tool,
          colorHex: SketchPalette.defaultHex
        ),
      ])
      let image = SketchStrokeRenderer.bake(
        drawing,
        size: CGSize(width: 80, height: 80),
        scale: 1
      )
      #expect(image != nil)
    }
  }
}
