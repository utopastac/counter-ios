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
    private var wasDisabled = false

    func setDisabled(_ disabled: Bool, from view: UIView) {
      resolveScrollView(from: view)
      guard let scrollView else { return }

      if disabled, !wasDisabled {
        // Horizontal reveal just locked scrolling — snap to the nearest page first. The last
        // page often sits slightly off-boundary (paging rounding / bounce), and freezing that
        // drift is what causes the visible jump when the drag ends.
        snapToNearestPageBoundary(scrollView)
      }
      wasDisabled = disabled

      if disabled {
        scrollView.panGestureRecognizer.isEnabled = false
        scrollView.setContentOffset(scrollView.contentOffset, animated: false)
        return
      }

      scrollView.panGestureRecognizer.isEnabled = true
    }

    /// Aligns to the closest page boundary using live scroll-view metrics (not SwiftUI state).
    private func snapToNearestPageBoundary(_ scrollView: UIScrollView) {
      let pageHeight = scrollView.bounds.height
      guard pageHeight > 1 else { return }

      let pageCount = max(1, Int(round(scrollView.contentSize.height / pageHeight)))
      let maxPageIndex = max(0, pageCount - 1)
      let nearestPage = min(
        max(Int(round(scrollView.contentOffset.y / pageHeight)), 0),
        maxPageIndex
      )
      let targetY = CGFloat(nearestPage) * pageHeight

      if abs(scrollView.contentOffset.y - targetY) > 0.5 {
        scrollView.setContentOffset(CGPoint(x: 0, y: targetY), animated: false)
      }
    }

    private func resolveScrollView(from view: UIView) {
      guard scrollView == nil else { return }
      scrollView = view.enclosingScrollView()
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
