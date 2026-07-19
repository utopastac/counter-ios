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
  /// Zero-based index of the selected pager page — used to snap content offset back to a
  /// page boundary whenever reveal locking toggles.
  var pageIndex: Int = 0
  /// Bump to force a snap (e.g. when the list reveal fully closes).
  var snapTrigger: Int = 0

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
    context.coordinator.apply(
      isDisabled: isDisabled,
      pageIndex: pageIndex,
      snapTrigger: snapTrigger,
      from: uiView
    )
  }

  final class Coordinator {
    private weak var scrollView: UIScrollView?
    private var lastDisabled: Bool?
    private var lastSnapTrigger = 0

    func apply(isDisabled: Bool, pageIndex: Int, snapTrigger: Int, from view: UIView) {
      resolveScrollView(from: view)
      guard let scrollView else { return }

      if snapTrigger != lastSnapTrigger || lastDisabled != isDisabled {
        snapToPage(scrollView, pageIndex: pageIndex)
        lastSnapTrigger = snapTrigger
        lastDisabled = isDisabled
      }

      if isDisabled {
        scrollView.panGestureRecognizer.isEnabled = false
        scrollView.setContentOffset(scrollView.contentOffset, animated: false)
        return
      }

      scrollView.panGestureRecognizer.isEnabled = true
    }

    private func snapToPage(_ scrollView: UIScrollView, pageIndex: Int) {
      let pageHeight = scrollView.bounds.height
      guard pageHeight > 1, pageIndex >= 0 else { return }

      let targetY = CGFloat(pageIndex) * pageHeight
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
