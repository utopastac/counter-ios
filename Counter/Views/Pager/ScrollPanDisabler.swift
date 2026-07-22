import SwiftUI
import UIKit

/// Disables a parent `UIScrollView` pan recognizer while reveal scroll is locked.
///
/// Still used by the underlay list and compact stack. The full-mode pager is a UIKit
/// `VerticalPagerScrollView` that gates its own pan. Reveal claiming also goes through
/// `ScrollPanGate` for immediate recognizer arbitration.
///
/// Never call `setContentOffset` here — correcting an interrupted offset is what caused
/// visible jumps on the last page / last list row.
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
      if disabled {
        if scrollView.bounces { scrollView.bounces = false }
        if scrollView.alwaysBounceVertical { scrollView.alwaysBounceVertical = false }
      }
      scrollView.panGestureRecognizer.isEnabled = !disabled
    }

    private func resolveScrollView(from view: UIView) {
      guard scrollView == nil else { return }
      var current: UIView? = view
      while let candidate = current {
        if let scroll = candidate as? UIScrollView {
          scrollView = scroll
          return
        }
        current = candidate.superview
      }
    }
  }
}

/// Disables vertical bounce on a SwiftUI `ScrollView` (compact stack). Full-mode paging
/// owns bounce inside `VerticalPagerScrollView` instead.
struct PagerScrollViewConfiguration: UIViewRepresentable {
  func makeUIView(context: Context) -> UIView {
    let view = UIView(frame: .zero)
    view.isUserInteractionEnabled = false
    view.backgroundColor = .clear
    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    var current: UIView? = uiView
    while let candidate = current {
      if let scroll = candidate as? UIScrollView {
        if scroll.bounces { scroll.bounces = false }
        if scroll.alwaysBounceVertical { scroll.alwaysBounceVertical = false }
        return
      }
      current = candidate.superview
    }
  }
}
