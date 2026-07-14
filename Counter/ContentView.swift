import SwiftUI
import SwiftData

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @State private var isBootstrapped = false

  var body: some View {
    Group {
      if isBootstrapped {
        CounterPagerView()
          .counterDesignSystemFromColorScheme()
          .homeIndicatorAlwaysVisible()
      }
    }
    .task {
      SampleDataSeeder.seedIfNeeded(in: modelContext)
      isBootstrapped = true
    }
  }
}

#Preview {
  PreviewModel.appRoot {
    ContentView()
  }
}
