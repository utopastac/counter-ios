import SwiftUI

/// Tracks the display refresh rate using a `CADisplayLink` and publishes a
/// smoothed frames-per-second reading roughly twice a second.
@MainActor
final class FPSMonitor: ObservableObject {
  @Published private(set) var fps: Int = 0

  private var displayLink: CADisplayLink?
  private var frameCount: Int = 0
  private var lastTimestamp: CFTimeInterval = 0

  func start() {
    guard displayLink == nil else { return }
    frameCount = 0
    lastTimestamp = 0
    let link = CADisplayLink(target: self, selector: #selector(step(_:)))
    link.add(to: .main, forMode: .common)
    displayLink = link
  }

  func stop() {
    displayLink?.invalidate()
    displayLink = nil
    fps = 0
  }

  @objc private func step(_ link: CADisplayLink) {
    if lastTimestamp == 0 {
      lastTimestamp = link.timestamp
      return
    }

    frameCount += 1
    let elapsed = link.timestamp - lastTimestamp
    guard elapsed >= 0.5 else { return }

    fps = Int((Double(frameCount) / elapsed).rounded())
    frameCount = 0
    lastTimestamp = link.timestamp
  }
}

/// Lightweight debug HUD pinned to a corner that reports the current frame rate.
struct FPSCounterView: View {
  @Environment(\.semanticColors) private var colors
  @StateObject private var monitor = FPSMonitor()

  var body: some View {
    Text("\(monitor.fps) FPS")
      .counterTextStyle(.button, color: .onInteractiveFill, compact: true)
      .padding(.horizontal, SpaceToken.u2)
      .padding(.vertical, SpaceToken.u1)
      .background(colors.interactivePrimaryFill, in: RadiusToken.continuousButton)
      .fixedSize()
      .allowsHitTesting(false)
      .accessibilityHidden(true)
      .onAppear { monitor.start() }
      .onDisappear { monitor.stop() }
  }
}

#Preview {
  FPSCounterView()
    .counterDesignSystemFromColorScheme()
}
