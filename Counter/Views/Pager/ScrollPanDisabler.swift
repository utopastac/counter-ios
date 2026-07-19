import SwiftUI
import UIKit

/// Disables a parent `UIScrollView` pan recognizer while a competing axis gesture is active.
///
/// Kept deliberately: the pager/list already call `.scrollDisabled` for the same flag, but
/// that alone does not reliably cancel an in-flight UIKit pan or stop the enclosing
/// `UIScrollView`'s recognizer from competing with the underlay's horizontal
/// `simultaneousGesture`. On iOS 26, `simultaneousGesture` no longer propagates to ancestor
/// scroll pans (release-notes fix for 147970990), so this bridge remains the hard lock for
/// reveal-vs-pager gesture arbitration.
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
      scrollView.panGestureRecognizer.isEnabled = !disabled
    }

    private func resolveScrollView(from view: UIView) {
      guard scrollView == nil else { return }
      scrollView = view.enclosingScrollView()
    }
  }
}

/// One-time UIKit configuration for the vertical paging `ScrollView`.
///
/// Disables vertical bounce so the last page cannot rubber-band past its boundary. An interrupted
/// bounce (horizontal reveal starting mid-overscroll) was a primary source of last-page jumps.
struct PagerScrollViewConfiguration: UIViewRepresentable {
  func makeUIView(context: Context) -> UIView {
    let view = UIView(frame: .zero)
    view.isUserInteractionEnabled = false
    view.backgroundColor = .clear
    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    guard let scrollView = uiView.enclosingScrollView() else { return }
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
