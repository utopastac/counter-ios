import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if os(watchOS)
import WatchKit
#endif

enum AppHaptics {
  static func impact() {
    guard AppAppearancePreference.isHapticsEnabled else { return }

    #if os(iOS)
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    #elseif os(watchOS)
    WKInterfaceDevice.current().play(.click)
    #endif
  }

  static func undo() {
    guard AppAppearancePreference.isHapticsEnabled else { return }

    #if os(iOS)
    UINotificationFeedbackGenerator().notificationOccurred(.warning)
    #elseif os(watchOS)
    WKInterfaceDevice.current().play(.click)
    #endif
  }
}
