import SwiftUI
import SwiftData

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @AppStorage(AppAppearancePreference.darkModeEnabledKey) private var isDarkModeEnabled = false
  @State private var isBootstrapped = false

  var body: some View {
    ZStack {
      CounterPagerView()
        .counterDesignSystemFromColorScheme()
        .opacity(isBootstrapped ? 1 : 0)

      BootSplashView()
        .opacity(isBootstrapped ? 0 : 1)
    }
    .animation(.easeOut(duration: 0.25), value: isBootstrapped)
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
