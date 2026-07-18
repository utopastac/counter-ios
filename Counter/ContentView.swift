import SwiftUI
import SwiftData

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @AppStorage(AppAppearancePreference.darkModeEnabledKey) private var isDarkModeEnabled = false
  @AppStorage(AppAppearancePreference.fpsCounterEnabledKey) private var isFPSCounterEnabled = false
  @State private var isBootstrapped = false
  @State private var sheetCoordinator = CounterSheetCoordinator()

  var body: some View {
    ZStack {
      CounterPagerView()
        .environment(sheetCoordinator)
        .counterDesignSystemFromColorScheme()
        .opacity(isBootstrapped ? 1 : 0)

      BootSplashView()
        .opacity(isBootstrapped ? 0 : 1)

      CounterSheetHost(coordinator: sheetCoordinator)
    }
    .overlay(alignment: .bottomTrailing) {
      if isFPSCounterEnabled {
        FPSCounterView()
          .counterDesignSystemFromColorScheme()
          .padding(.trailing, SpaceToken.pageMargin)
          .padding(.bottom, SpaceToken.pageFooterBottom)
      }
    }
    .animation(.easeOut(duration: 0.25), value: isBootstrapped)
    .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
    .task {
      WatchSyncCoordinator.shared.activate()
      SampleDataSeeder.seedIfNeeded(in: modelContext)
      WatchSyncEngine.publishFullSnapshot(in: modelContext)
      isBootstrapped = true
    }
  }
}

#Preview {
  PreviewModel.appRoot {
    ContentView()
  }
}
