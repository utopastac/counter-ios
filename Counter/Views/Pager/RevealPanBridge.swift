import SwiftUI
import UIKit

/// UIKit pan that owns horizontal list-reveal, with real recognizer arbitration against
/// vertical scroll views in the same underlay container.
///
/// Replaces SwiftUI `DragGesture` + `simultaneousGesture`, which cannot reliably win against
/// ancestor/`UIScrollView` pans on iOS 26 (RN 147970990). On a horizontal claim this bridge
/// disables scroll pans under the underlay root directly — no SwiftUI `.scrollDisabled`,
/// no `setContentOffset` correction.
///
/// The representable view itself is non-interactive; the pan is installed on the card
/// superview so buttons keep receiving taps.
struct RevealPanBridge: UIViewRepresentable {
  var state: RevealState
  var maxOffset: CGFloat
  @Binding var isRevealed: Bool
  var reduceMotion: Bool

  func makeCoordinator() -> Coordinator {
    Coordinator(state: state)
  }

  func makeUIView(context: Context) -> UIView {
    let view = UIView(frame: .zero)
    view.isUserInteractionEnabled = false
    view.backgroundColor = .clear
    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    context.coordinator.state = state
    context.coordinator.maxOffset = maxOffset
    context.coordinator.isRevealed = $isRevealed
    context.coordinator.reduceMotion = reduceMotion
    context.coordinator.install(on: uiView)
  }

  final class Coordinator: NSObject, UIGestureRecognizerDelegate {
    var state: RevealState
    var maxOffset: CGFloat = 0
    var isRevealed: Binding<Bool> = .constant(false)
    var reduceMotion = false

    private weak var hostView: UIView?
    private var pan: UIPanGestureRecognizer?
    private var dragStartOffset: CGFloat = 0
    private var axis: Axis?
    private var unlockWorkItem: DispatchWorkItem?

    private enum Axis {
      case horizontal
      case vertical
    }

    init(state: RevealState) {
      self.state = state
    }

    func install(on view: UIView) {
      hostView = view
      guard let superview = view.superview else { return }

      if let pan {
        if pan.view !== superview {
          pan.view?.removeGestureRecognizer(pan)
          superview.addGestureRecognizer(pan)
        }
        return
      }

      let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
      pan.delegate = self
      pan.cancelsTouchesInView = false
      pan.maximumNumberOfTouches = 1
      superview.addGestureRecognizer(pan)
      self.pan = pan
    }

    func gestureRecognizer(
      _ gestureRecognizer: UIGestureRecognizer,
      shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
      // Once horizontal reveal claims the touch, stop sharing with scroll pans.
      axis != .horizontal
    }

    @objc private func handlePan(_ pan: UIPanGestureRecognizer) {
      guard let view = pan.view else { return }
      let translation = pan.translation(in: view)

      switch pan.state {
      case .began:
        axis = nil
        dragStartOffset = state.cardOffset

      case .changed:
        if axis == nil {
          let distance = max(abs(translation.x), abs(translation.y))
          guard distance >= RevealToken.axisDecisionDistance else { return }
          let next: Axis = abs(translation.x) > abs(translation.y) ? .horizontal : .vertical
          axis = next
          if next == .horizontal {
            claimHorizontal(from: view)
          }
        }

        guard axis == .horizontal else { return }
        let nextOffset = rubberBand(dragStartOffset + translation.x, max: maxOffset)
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
          state.cardOffset = nextOffset
        }

      case .ended, .cancelled, .failed:
        let claimedHorizontal = axis == .horizontal
        axis = nil

        guard claimedHorizontal else {
          releaseHorizontal()
          return
        }

        let velocity = pan.velocity(in: view)
        // Project ~200ms of inertia — matches the old SwiftUI predictedEndTranslation feel.
        let predictedX = translation.x + velocity.x * 0.2
        let predicted = rubberBand(dragStartOffset + predictedX, max: maxOffset)
        let shouldOpen = shouldSettleOpen(
          predicted: predicted,
          maxOffset: maxOffset,
          startedOpen: dragStartOffset > maxOffset * 0.5
        )
        let target = shouldOpen ? maxOffset : 0

        withAnimation(MotionToken.settle(reduceMotion: reduceMotion)) {
          state.cardOffset = target
          isRevealed.wrappedValue = shouldOpen
        }
        scheduleUnlock()
        DispatchQueue.main.async { [weak self] in
          self?.state.isDragging = false
        }

      default:
        break
      }
    }

    private func claimHorizontal(from view: UIView) {
      unlockWorkItem?.cancel()
      unlockWorkItem = nil
      state.isDragging = true
      state.locksScroll = true
      ScrollPanGate.setScrollPansEnabled(false, underlayRootFrom: view)
    }

    private func releaseHorizontal() {
      state.isDragging = false
      state.locksScroll = false
      if let view = hostView ?? pan?.view {
        ScrollPanGate.setScrollPansEnabled(true, underlayRootFrom: view)
      }
    }

    private func scheduleUnlock() {
      unlockWorkItem?.cancel()
      let duration = reduceMotion ? MotionToken.reduceMotionDuration : MotionToken.revealSettleDuration
      let work = DispatchWorkItem { [weak self] in
        guard let self else { return }
        self.state.locksScroll = false
        if let view = self.hostView ?? self.pan?.view {
          ScrollPanGate.setScrollPansEnabled(true, underlayRootFrom: view)
        }
        self.unlockWorkItem = nil
      }
      unlockWorkItem = work
      DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: work)
    }

    private func shouldSettleOpen(
      predicted: CGFloat,
      maxOffset: CGFloat,
      startedOpen: Bool
    ) -> Bool {
      guard maxOffset > 0 else { return false }
      let threshold = maxOffset * (startedOpen ? 0.45 : 0.35)
      return predicted > threshold
    }

    private func rubberBand(_ value: CGFloat, max: CGFloat) -> CGFloat {
      if value > max {
        return max + (value - max) * 0.16
      }
      if value < 0 {
        return value * 0.16
      }
      return value
    }
  }
}

/// Enables/disables every `UIScrollView` pan under the underlay container that hosts
/// both the counters list and the pager card.
enum ScrollPanGate {
  static func setScrollPansEnabled(_ enabled: Bool, underlayRootFrom view: UIView) {
    guard let root = underlayRoot(from: view) else { return }
    apply(enabled, in: root)
  }

  private static func underlayRoot(from view: UIView) -> UIView? {
    var current: UIView? = view
    var fallback = view
    while let candidate = current {
      fallback = candidate
      if candidate.superview is UIWindow {
        return candidate
      }
      current = candidate.superview
    }
    return fallback
  }

  private static func apply(_ enabled: Bool, in root: UIView) {
    if let scroll = root as? UIScrollView {
      if !enabled {
        if scroll.bounces { scroll.bounces = false }
        if scroll.alwaysBounceVertical { scroll.alwaysBounceVertical = false }
      }
      scroll.panGestureRecognizer.isEnabled = enabled
    }
    for child in root.subviews {
      apply(enabled, in: child)
    }
  }
}
