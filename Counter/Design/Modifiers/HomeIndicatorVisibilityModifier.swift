import SwiftUI

#if canImport(UIKit)
import UIKit
import ObjectiveC
#endif

extension View {
  /// Keeps the system home indicator visible instead of auto-hiding during scroll interaction.
  func homeIndicatorAlwaysVisible() -> some View {
    persistentSystemOverlays(.visible)
      #if canImport(UIKit)
      .background(HomeIndicatorVisibilityHost())
      #endif
  }
}

#if canImport(UIKit)
private enum HomeIndicatorVisibilityPolicy {
  static let controller = HomeIndicatorPolicyController()

  private static var isInstalled = false
  private static var isActive = false

  static func installIfNeeded() {
    guard !isInstalled else { return }
    isInstalled = true
    UIViewController.installHomeIndicatorVisibilitySwizzle()
  }

  static func activate() {
    installIfNeeded()
    guard !isActive else { return }
    isActive = true
    refresh()
  }

  static var forcesVisible: Bool {
    isActive
  }

  private static func refresh() {
    controller.setNeedsUpdateOfHomeIndicatorAutoHidden()
    for scene in UIApplication.shared.connectedScenes {
      guard let windowScene = scene as? UIWindowScene else { continue }
      for window in windowScene.windows {
        window.rootViewController?.setNeedsUpdateOfHomeIndicatorAutoHidden()
      }
    }
  }
}

private final class HomeIndicatorPolicyController: UIViewController {
  override var prefersHomeIndicatorAutoHidden: Bool { false }

  override var childForHomeIndicatorAutoHidden: UIViewController? { nil }
}

private struct HomeIndicatorVisibilityHost: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> UIViewController {
    HomeIndicatorVisibilityPolicy.installIfNeeded()
    let viewController = UIViewController()
    viewController.view.isUserInteractionEnabled = false
    viewController.view.backgroundColor = .clear
    return viewController
  }

  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    HomeIndicatorVisibilityPolicy.activate()
  }
}

private extension UIViewController {
  static func installHomeIndicatorVisibilitySwizzle() {
    let originalSelector = #selector(getter: childForHomeIndicatorAutoHidden)
    let swizzledSelector = #selector(counter_swizzledChildForHomeIndicatorAutoHidden)

    guard
      let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector),
      let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzledSelector)
    else { return }

    method_exchangeImplementations(originalMethod, swizzledMethod)
  }

  @objc func counter_swizzledChildForHomeIndicatorAutoHidden() -> UIViewController? {
    if HomeIndicatorVisibilityPolicy.forcesVisible {
      return HomeIndicatorVisibilityPolicy.controller
    }

    return counter_swizzledChildForHomeIndicatorAutoHidden()
  }
}
#endif
