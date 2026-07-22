import SwiftUI

struct NoHighlightButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
  }
}

struct IconButtonStyle: ButtonStyle {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .opacity(configuration.isPressed ? OpacityToken.iconButtonPressed : 1)
      .animation(reduceMotion ? nil : .easeOut(duration: MotionToken.iconButtonPressDuration), value: configuration.isPressed)
  }
}

/// Uses a tap gesture so the action does not fire after a scroll that began on the button.
/// `.plain` / `ButtonStyle` presses often complete on finger-up inside a `ScrollView`.
struct ScrollSafeButtonStyle: PrimitiveButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .contentShape(Rectangle())
      .onTapGesture(perform: configuration.trigger)
  }
}

extension ButtonStyle where Self == NoHighlightButtonStyle {
  static var noHighlight: NoHighlightButtonStyle {
    NoHighlightButtonStyle()
  }
}

extension ButtonStyle where Self == IconButtonStyle {
  static var icon: IconButtonStyle {
    IconButtonStyle()
  }
}

extension PrimitiveButtonStyle where Self == ScrollSafeButtonStyle {
  static var scrollSafe: ScrollSafeButtonStyle {
    ScrollSafeButtonStyle()
  }
}
