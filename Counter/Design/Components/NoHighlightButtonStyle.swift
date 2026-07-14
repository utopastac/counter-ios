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
