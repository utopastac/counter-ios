import SwiftUI
import UIKit

/// Finger samples become an in-progress stroke. Spacing matches Doodleoop so fast strokes stay smooth.
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

struct SketchCanvas: View {
  @Binding var drawing: SketchDrawing
  var tool: SketchTool
  var colorHex: String
  var lineWidth: Double
  var onWillCommitStroke: (() -> Void)?
  var onCanvasSizeChange: (CGSize) -> Void

  @Environment(\.displayScale) private var displayScale

  @State private var liveStroke = SketchLiveStroke()
  @State private var bakedImage: UIImage?
  @State private var bakedStrokeCount = 0
  @State private var canvasSize: CGSize = .zero

  var body: some View {
    let isLiveErasing = liveStroke.isLiveErasing

    ZStack {
      if let bakedImage, !isLiveErasing {
        Image(uiImage: bakedImage)
          .resizable()
          .interpolation(.high)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }

      Canvas { context, size in
        if isLiveErasing {
          SketchStrokeRenderer.drawDrawing(
            drawing,
            liveStroke: liveStroke.currentStroke,
            in: &context,
            size: size
          )
        } else if let currentStroke = liveStroke.currentStroke {
          SketchStrokeRenderer.draw(currentStroke, in: &context, size: size, live: true)
        }
      }
    }
    .background(SketchChrome.paper)
    .overlay {
      Rectangle()
        .strokeBorder(SketchChrome.gridLine, lineWidth: SketchChrome.borderThin)
    }
    .background {
      GeometryReader { geo in
        Color.clear
          .onAppear { updateCanvasSize(geo.size) }
          .onChange(of: geo.size) { _, newSize in updateCanvasSize(newSize) }
      }
    }
    .onChange(of: drawing) { _, newDrawing in
      reconcileBake(with: newDrawing)
    }
    .overlay {
      SketchTouchCapture(
        onSamples: { samples, size in
          for sample in samples {
            liveStroke.appendSample(
              at: sample.location,
              timestamp: sample.timestamp,
              in: size,
              tool: tool,
              colorHex: colorHex,
              lineWidth: lineWidth
            )
          }
        },
        onEnded: { location, size in
          guard let stroke = liveStroke.finish(
            at: location,
            in: size,
            tool: tool,
            lineWidth: lineWidth
          ) else { return }
          onWillCommitStroke?()
          drawing.strokes.append(stroke)
        }
      )
    }
  }

  private func updateCanvasSize(_ size: CGSize) {
    let rounded = CGSize(width: size.width.rounded(), height: size.height.rounded())
    guard rounded != canvasSize else { return }
    canvasSize = rounded
    onCanvasSizeChange(rounded)
    bakedImage = nil
    bakedStrokeCount = -1
    reconcileBake(with: drawing)
  }

  private func reconcileBake(with drawing: SketchDrawing) {
    guard canvasSize.width > 1, canvasSize.height > 1 else { return }
    if drawing.strokes.isEmpty {
      bakedImage = nil
      bakedStrokeCount = 0
      return
    }
    guard drawing.strokes.count != bakedStrokeCount || bakedImage == nil else { return }
    bakedImage = SketchStrokeRenderer.bake(drawing, size: canvasSize, scale: displayScale)
    bakedStrokeCount = drawing.strokes.count
  }
}

/// Coalesced UIKit touches. A claim pan keeps the sheet from stealing a stroke.
private struct SketchTouchCapture: UIViewRepresentable {
  struct Sample {
    var location: CGPoint
    var timestamp: TimeInterval
  }

  var onSamples: ([Sample], CGSize) -> Void
  var onEnded: (CGPoint, CGSize) -> Void

  func makeUIView(context: Context) -> TouchView {
    let view = TouchView()
    view.onSamples = onSamples
    view.onEnded = onEnded
    return view
  }

  func updateUIView(_ uiView: TouchView, context: Context) {
    uiView.onSamples = onSamples
    uiView.onEnded = onEnded
  }

  final class TouchView: UIView {
    var onSamples: (([Sample], CGSize) -> Void)?
    var onEnded: ((CGPoint, CGSize) -> Void)?

    private let claimPan = UIPanGestureRecognizer()
    private var didClaimPans = false

    override init(frame: CGRect) {
      super.init(frame: frame)
      isMultipleTouchEnabled = false
      backgroundColor = .clear
      isOpaque = false
      claimPan.cancelsTouchesInView = false
      claimPan.delaysTouchesBegan = false
      claimPan.delaysTouchesEnded = false
      addGestureRecognizer(claimPan)
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
      super.didMoveToWindow()
      didClaimPans = false
      guard window != nil else { return }
      DispatchQueue.main.async { [weak self] in
        self?.claimAncestorPans()
      }
    }

    override func layoutSubviews() {
      super.layoutSubviews()
      guard window != nil, !didClaimPans else { return }
      claimAncestorPans()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      emit(touches, event: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
      emit(touches, event: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
      emit(touches, event: event)
      if let touch = touches.first {
        onEnded?(touch.location(in: self), bounds.size)
      }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
      touchesEnded(touches, with: event)
    }

    private func emit(_ touches: Set<UITouch>, event: UIEvent?) {
      guard let touch = touches.first else { return }
      let coalesced = event?.coalescedTouches(for: touch) ?? [touch]
      let samples = coalesced.map {
        Sample(location: $0.location(in: self), timestamp: $0.timestamp)
      }
      onSamples?(samples, bounds.size)
    }

    /// Sheet pan waits until this canvas pan fails, so a stroke doesn't drag the sheet.
    private func claimAncestorPans() {
      var view = superview
      var claimed = false
      while let current = view {
        for case let pan as UIPanGestureRecognizer in current.gestureRecognizers ?? [] where pan !== claimPan {
          pan.require(toFail: claimPan)
          claimed = true
        }
        view = current.superview
      }
      if claimed { didClaimPans = true }
    }
  }
}
