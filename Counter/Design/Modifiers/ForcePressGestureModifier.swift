import SwiftUI
import UIKit

/// Fires when the user presses firmly (3D Touch / force) or, on devices without
/// force capability, after a short press-and-hold (Haptic Touch).
struct ForcePressGesture: UIGestureRecognizerRepresentable {
  var minimumForceFraction: CGFloat = 0.55
  var fallbackDuration: TimeInterval = 0.4
  let action: () -> Void

  func makeUIGestureRecognizer(context: Context) -> ForcePressGestureRecognizer {
    let recognizer = ForcePressGestureRecognizer(
      minimumForceFraction: minimumForceFraction,
      fallbackDuration: fallbackDuration
    )
    recognizer.cancelsTouchesInView = false
    recognizer.delegate = context.coordinator
    return recognizer
  }

  func updateUIGestureRecognizer(
    _ recognizer: ForcePressGestureRecognizer,
    context: Context
  ) {
    recognizer.minimumForceFraction = minimumForceFraction
    recognizer.fallbackDuration = fallbackDuration
  }

  func handleUIGestureRecognizerAction(
    _ recognizer: ForcePressGestureRecognizer,
    context: Context
  ) {
    guard recognizer.state == .ended || recognizer.state == .recognized else { return }
    action()
  }

  func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
    Coordinator()
  }

  final class Coordinator: NSObject, UIGestureRecognizerDelegate {
    func gestureRecognizer(
      _ gestureRecognizer: UIGestureRecognizer,
      shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
      true
    }
  }
}

final class ForcePressGestureRecognizer: UIGestureRecognizer {
  var minimumForceFraction: CGFloat
  var fallbackDuration: TimeInterval

  private var fallbackWorkItem: DispatchWorkItem?
  private var hasFired = false

  init(minimumForceFraction: CGFloat, fallbackDuration: TimeInterval) {
    self.minimumForceFraction = minimumForceFraction
    self.fallbackDuration = fallbackDuration
    super.init(target: nil, action: nil)
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    guard touches.count == 1 else {
      state = .failed
      return
    }
    hasFired = false
    state = .began
    scheduleFallback()
    evaluateForce(in: touches)
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    evaluateForce(in: touches)
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    cancelFallback()
    if state == .ended || hasFired {
      // Already recognized via force / fallback.
      return
    }
    state = .cancelled
  }

  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
    cancelFallback()
    if state == .ended {
      return
    }
    state = .cancelled
  }

  override func reset() {
    cancelFallback()
    hasFired = false
  }

  private func evaluateForce(in touches: Set<UITouch>) {
    guard !hasFired, let touch = touches.first else { return }
    let forceTouchAvailable = view?.traitCollection.forceTouchCapability == .available
    let supportsForce = forceTouchAvailable && touch.maximumPossibleForce > 0
    guard supportsForce else { return }

    let fraction = touch.force / touch.maximumPossibleForce
    if fraction >= minimumForceFraction {
      fire()
    }
  }

  private func scheduleFallback() {
    cancelFallback()
    let work = DispatchWorkItem { [weak self] in
      self?.fire()
    }
    fallbackWorkItem = work
    DispatchQueue.main.asyncAfter(deadline: .now() + fallbackDuration, execute: work)
  }

  private func cancelFallback() {
    fallbackWorkItem?.cancel()
    fallbackWorkItem = nil
  }

  private func fire() {
    guard !hasFired else { return }
    hasFired = true
    cancelFallback()
    state = .ended
  }
}

extension View {
  func onForcePress(perform action: @escaping () -> Void) -> some View {
    gesture(ForcePressGesture(action: action))
  }
}
