import SwiftUI
import UIKit

/// UIKit-owned vertical pager. Owns bounce, paging, and content offset so SwiftUI cannot
/// re-assert `scrollPosition` or re-enable rubber-banding on the last page.
struct VerticalPagerScrollView<Content: View>: UIViewControllerRepresentable {
  var pageHeight: CGFloat
  var pageIDs: [String]
  @Binding var selectedPageID: String?
  var scrollState: PagerScrollState
  var revealState: RevealState
  var isListRevealed: Bool
  var pendingPageID: String?
  var onPendingHandled: () -> Void
  @ViewBuilder var content: () -> Content

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeUIViewController(context: Context) -> PagerScrollViewController {
    let controller = PagerScrollViewController()
    context.coordinator.controller = controller
    controller.scrollState = scrollState
    controller.onSelectPage = { [binding = $selectedPageID] pageID in
      if binding.wrappedValue != pageID {
        binding.wrappedValue = pageID
      }
    }
    return controller
  }

  func updateUIViewController(_ controller: PagerScrollViewController, context: Context) {
    controller.scrollState = scrollState
    controller.onSelectPage = { [binding = $selectedPageID] pageID in
      if binding.wrappedValue != pageID {
        binding.wrappedValue = pageID
      }
    }

    let pageContent = content()
    controller.setContent(
      pageContent,
      pageHeight: pageHeight,
      pageIDs: pageIDs
    )

    let locked = (revealState.locksScroll || isListRevealed) && pendingPageID == nil
    controller.setScrollLocked(locked)

    if let pendingPageID {
      controller.scrollToPage(pendingPageID, animated: false)
      onPendingHandled()
    } else if let selectedPageID,
              controller.currentPageID != selectedPageID,
              !controller.isUserScrolling {
      // Keep UIKit offset aligned after external selection changes (create / deep link)
      // without fighting an in-flight user drag.
      controller.scrollToPage(selectedPageID, animated: false)
    }
  }

  final class Coordinator {
    weak var controller: PagerScrollViewController?
  }
}

final class PagerScrollViewController: UIViewController, UIScrollViewDelegate {
  private let scrollView = UIScrollView()
  private var hostController: UIHostingController<AnyView>?
  private var pageHeight: CGFloat = 0
  private var pageIDs: [String] = []

  var scrollState: PagerScrollState?
  var onSelectPage: ((String) -> Void)?

  private(set) var isUserScrolling = false
  private(set) var currentPageID: String?

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.backgroundColor = .clear
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.isPagingEnabled = true
    scrollView.bounces = false
    scrollView.alwaysBounceVertical = false
    scrollView.contentInsetAdjustmentBehavior = .never
    scrollView.contentInset = .zero
    scrollView.delegate = self
    view.addSubview(scrollView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    layoutHostedContent()
  }

  func setContent<Content: View>(_ content: Content, pageHeight: CGFloat, pageIDs: [String]) {
    self.pageHeight = pageHeight
    self.pageIDs = pageIDs

    let wrapped = AnyView(content)
    if let hostController {
      hostController.rootView = wrapped
    } else {
      let host = UIHostingController(rootView: wrapped)
      host.view.backgroundColor = .clear
      host.safeAreaRegions = []
      addChild(host)
      scrollView.addSubview(host.view)
      host.didMove(toParent: self)
      hostController = host
    }

    layoutHostedContent()
    // Re-assert bounce each update — hosting churn can reset UIScrollView defaults.
    scrollView.bounces = false
    scrollView.alwaysBounceVertical = false
  }

  func setScrollLocked(_ locked: Bool) {
    scrollView.panGestureRecognizer.isEnabled = !locked
    scrollView.isScrollEnabled = !locked
  }

  func scrollToPage(_ pageID: String, animated: Bool) {
    guard let index = pageIDs.firstIndex(of: pageID), pageHeight > 0 else { return }
    let target = CGPoint(x: 0, y: CGFloat(index) * pageHeight)
    if animated {
      scrollView.setContentOffset(target, animated: true)
    } else {
      scrollView.setContentOffset(target, animated: false)
    }
    currentPageID = pageID
    scrollState?.value = CGFloat(index)
  }

  private func layoutHostedContent() {
    guard let hostView = hostController?.view, pageHeight > 0, !pageIDs.isEmpty else { return }
    let width = scrollView.bounds.width
    guard width > 0 else { return }

    let contentHeight = pageHeight * CGFloat(pageIDs.count)
    hostView.frame = CGRect(x: 0, y: 0, width: width, height: contentHeight)
    scrollView.contentSize = CGSize(width: width, height: contentHeight)

    if let currentPageID,
       let index = pageIDs.firstIndex(of: currentPageID),
       !isUserScrolling {
      let expectedY = CGFloat(index) * pageHeight
      if abs(scrollView.contentOffset.y - expectedY) > 0.5 {
        scrollView.setContentOffset(CGPoint(x: 0, y: expectedY), animated: false)
      }
    }
  }

  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    isUserScrolling = true
    scrollState?.isDragging = true
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard pageHeight > 0 else { return }
    let progress = scrollView.contentOffset.y / pageHeight
    scrollState?.value = progress

    let index = Int(progress.rounded())
    let clamped = min(max(index, 0), max(pageIDs.count - 1, 0))
    guard pageIDs.indices.contains(clamped) else { return }
    let pageID = pageIDs[clamped]
    if pageID != currentPageID {
      currentPageID = pageID
      onSelectPage?(pageID)
    }
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      finishUserScroll()
    }
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    finishUserScroll()
  }

  func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    finishUserScroll()
  }

  private func finishUserScroll() {
    isUserScrolling = false
    scrollState?.isDragging = false
    snapToNearestPage()
  }

  private func snapToNearestPage() {
    guard pageHeight > 0, !pageIDs.isEmpty else { return }
    let index = Int((scrollView.contentOffset.y / pageHeight).rounded())
    let clamped = min(max(index, 0), pageIDs.count - 1)
    let target = CGFloat(clamped) * pageHeight
    if abs(scrollView.contentOffset.y - target) > 0.5 {
      scrollView.setContentOffset(CGPoint(x: 0, y: target), animated: false)
    }
    let pageID = pageIDs[clamped]
    currentPageID = pageID
    scrollState?.value = CGFloat(clamped)
    onSelectPage?(pageID)
  }
}
