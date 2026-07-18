import SwiftUI
import UIKit

/// Disables a parent `UIScrollView` pan recognizer while a competing axis gesture is active.
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
        scrollView.panGestureRecognizer.isEnabled = false
        scrollView.setContentOffset(scrollView.contentOffset, animated: false)
        return
      }

      scrollView.panGestureRecognizer.isEnabled = true
    }

    private func resolveScrollView(from view: UIView) {
      guard scrollView == nil else { return }
      scrollView = view.enclosingScrollView()
    }
  }
}

/// Keeps the pager's content inset fixed while a sheet is presented over it.
///
/// A paging `ScrollView` positions its pages using the system's automatic content-inset
/// adjustment (top inset == device safe area). Presenting a `.sheet` shrinks the presenter's
/// safe area to build the card-stack, then restores it on dismiss — and that animated inset
/// change drags the pager content up/down (worse with the keyboard). Freezing the inset to its
/// resting value for the duration of the presentation makes the pager immune; automatic
/// behavior resumes once the transition has fully settled.
struct PagerScrollInsetLock: UIViewRepresentable {
  var isSheetPresented: Bool

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
    context.coordinator.apply(isSheetPresented: isSheetPresented, from: uiView)
  }

  final class Coordinator {
    private weak var scrollView: UIScrollView?
    private var isFrozen = false
    private var restoreWorkItem: DispatchWorkItem?
    private var lastRestingInset: UIEdgeInsets?

    func apply(isSheetPresented: Bool, from view: UIView) {
      if scrollView == nil {
        scrollView = view.enclosingScrollView()
      }
      guard let scrollView else { return }

      if isSheetPresented {
        freeze(scrollView)
      } else {
        // Genuinely at rest: remember the correct inset so we can pin to it the next time a
        // sheet presents (page-hosted sheets signal slightly after their safe-area change begins).
        if !isFrozen {
          let resting = scrollView.adjustedContentInset
          if resting.top > 0 || resting.bottom > 0 {
            lastRestingInset = resting
          }
        }
        scheduleRestore(scrollView)
      }
    }

    private func freeze(_ scrollView: UIScrollView) {
      restoreWorkItem?.cancel()
      restoreWorkItem = nil
      guard !isFrozen else { return }

      let resting = lastRestingInset ?? scrollView.adjustedContentInset
      scrollView.contentInsetAdjustmentBehavior = .never
      scrollView.contentInset = resting
      scrollView.verticalScrollIndicatorInsets.top = resting.top
      isFrozen = true
    }

    private func scheduleRestore(_ scrollView: UIScrollView) {
      guard isFrozen, restoreWorkItem == nil else { return }

      // Wait for the dismiss + safe-area animation to finish before handing control back to
      // the system, so restoring automatic adjustment doesn't itself cause a visible jump.
      let work = DispatchWorkItem { [weak self, weak scrollView] in
        guard let self, let scrollView else { return }
        scrollView.contentInsetAdjustmentBehavior = .automatic
        scrollView.contentInset = .zero
        self.isFrozen = false
        self.restoreWorkItem = nil
      }
      restoreWorkItem = work
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.55, execute: work)
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
