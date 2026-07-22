import SwiftUI
import UIKit

/// Disables a parent `UIScrollView` pan recognizer while a competing axis gesture is active.
///
/// Kept deliberately: pure `.scrollDisabled` is not a full substitute — it does not hard-disable
/// the underlying UIKit pan recognizer or stop an in-flight pan from competing with the
/// underlay's horizontal `simultaneousGesture`. On iOS 26, `simultaneousGesture` no longer
/// propagates to ancestor scroll pans (release-notes fix for 147970990), so this bridge remains
/// the hard lock for reveal-vs-pager gesture arbitration.
///
/// Call sites must not toggle SwiftUI `.scrollDisabled` for the same mid-reveal lock — that
/// reconciles content offset and jumps (worst on the last pager page / last list row).
///
/// Critical: never call `setContentOffset` here. Freezing or "correcting" the offset when the
/// pan is interrupted is what caused visible jumps (especially on the last page, where bounce
/// leaves the offset past the final page boundary). Just gate the recognizer.
struct ScrollPanDisabler: UIViewRepresentable {
  let isDisabled: Bool

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeUIView(context: Context) -> UIView {
    let view = UIView(frame: .zero)
    view.isUserInteractionEnabled = false
    view.backgroundColor = .clear
    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    context.coordinator.setDisabled(isDisabled, from: uiView)
  }

  final class Coordinator {
    private weak var scrollView: UIScrollView?

    func setDisabled(_ disabled: Bool, from view: UIView) {
      resolveScrollView(from: view)
      guard let scrollView else { return }
      // Re-assert before gating the pan — SwiftUI may have re-enabled bounce since the
      // last layout pass, and an interrupted overscroll on the last page is the jump.
      if disabled {
        if scrollView.bounces { scrollView.bounces = false }
        if scrollView.alwaysBounceVertical { scrollView.alwaysBounceVertical = false }
      }
      scrollView.panGestureRecognizer.isEnabled = !disabled
    }

    private func resolveScrollView(from view: UIView) {
      guard scrollView == nil else { return }
      scrollView = view.enclosingScrollView()
    }
  }
}

/// UIKit configuration for the vertical paging / compact `ScrollView`.
///
/// Disables vertical bounce so the last page cannot rubber-band past its boundary. An interrupted
/// bounce (horizontal reveal starting mid-overscroll) was a primary source of last-page jumps.
///
/// SwiftUI periodically resets `UIScrollView.bounces`, so this reapplies on every layout pass
/// and once after the current update cycle — a one-shot `updateUIView` is not enough.
struct PagerScrollViewConfiguration: UIViewRepresentable {
  func makeUIView(context: Context) -> PagerScrollConfigurationView {
    PagerScrollConfigurationView()
  }

  func updateUIView(_ uiView: PagerScrollConfigurationView, context: Context) {
    uiView.applyBounceDisabled()
    // SwiftUI often writes scroll-view defaults after representable updates; re-assert next turn.
    DispatchQueue.main.async {
      uiView.applyBounceDisabled()
    }
  }
}

final class PagerScrollConfigurationView: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false
    backgroundColor = .clear
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    applyBounceDisabled()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    applyBounceDisabled()
  }

  func applyBounceDisabled() {
    guard let scrollView = enclosingScrollView() else { return }
    if scrollView.bounces {
      scrollView.bounces = false
    }
    if scrollView.alwaysBounceVertical {
      scrollView.alwaysBounceVertical = false
    }
  }
}

private extension UIView {
  func enclosingScrollView() -> UIScrollView? {
    var current: UIView? = self
    while let candidate = current {
      if let scroll = candidate as? UIScrollView {
        return scroll
      }
      current = candidate.superview
    }
    return nil
  }
}
