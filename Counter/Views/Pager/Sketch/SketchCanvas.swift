import SwiftUI
import UIKit

struct SketchCanvas: View {
  @Binding var drawing: SketchDrawing
  var tool: SketchTool
  var colorHex: String
  var lineWidth: Double
  var onWillCommitStroke: (() -> Void)?
  var onCanvasSizeChange: (CGSize) -> Void

  @Environment(\.displayScale) private var displayScale
  @Environment(\.semanticColors) private var colors

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
    .background(colors.surfaceSheet)
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
    .onChange(of: colors.surfaceSheet) { _, _ in
      bakedImage = nil
      bakedStrokeCount = -1
      reconcileBake(with: drawing)
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
    .clipShape(RadiusToken.continuousListCard)
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
    bakedImage = SketchStrokeRenderer.bake(
      drawing,
      size: canvasSize,
      scale: displayScale,
      background: colors.surfaceSheet
    )
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
