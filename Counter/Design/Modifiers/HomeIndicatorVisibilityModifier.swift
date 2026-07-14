import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

extension View {
  /// Keeps the system home indicator visible instead of auto-hiding during scroll interaction.
  func homeIndicatorAlwaysVisible() -> some View {
    persistentSystemOverlays(.visible)
      .background {
        #if canImport(UIKit)
        HomeIndicatorVisibleHost()
        #else
        EmptyView()
        #endif
      }
  }
}

#if canImport(UIKit)
private struct HomeIndicatorVisibleHost: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> HomeIndicatorVisibleViewController {
    HomeIndicatorVisibleViewController()
  }

  func updateUIViewController(_ uiViewController: HomeIndicatorVisibleViewController, context: Context) {}
}

private final class HomeIndicatorVisibleViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    view.isUserInteractionEnabled = false
    view.backgroundColor = .clear
  }

  override var prefersHomeIndicatorAutoHidden: Bool { false }

  override var childForHomeIndicatorAutoHidden: UIViewController? { nil }
}
#endif
