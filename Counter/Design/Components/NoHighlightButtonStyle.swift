import SwiftUI

struct NoHighlightButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
  }
}

extension ButtonStyle where Self == NoHighlightButtonStyle {
  static var noHighlight: NoHighlightButtonStyle {
    NoHighlightButtonStyle()
  }
}
