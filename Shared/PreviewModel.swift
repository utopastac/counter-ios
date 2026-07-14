import SwiftData
import SwiftUI

enum PreviewModel {
  static var container: ModelContainer {
    SharedModelContainer.shared
  }

  @MainActor
  static func appRoot<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
      .modelContainer(container)
      .counterDesignSystemFromColorScheme()
  }
}
