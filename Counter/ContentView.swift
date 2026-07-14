import SwiftUI
import SwiftData

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @AppStorage(AppAppearancePreference.darkModeEnabledKey) private var isDarkModeEnabled = false
  @State private var isBootstrapped = false

  var body: some View {
    Group {
      if isBootstrapped {
        CounterPagerView()
          .counterDesignSystemFromColorScheme()
      } else {
        Color.clear
      }
    }
    .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
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
