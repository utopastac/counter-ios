import SwiftUI

struct CounterPageBackground: View {
  @Environment(\.semanticColors) private var colors

  var body: some View {
    colors.surfaceBackdrop
      .ignoresSafeArea()
  }
}
