import SwiftUI
import SwiftData

@Observable
@MainActor
final class CounterFocusRouter {
  /// Counter to show after a widget (or other) deep link. Cleared once the pager focuses it.
  var pendingCounterID: UUID?

  func handle(_ url: URL) {
    guard let id = CounterDeepLink.counterID(from: url) else { return }
    pendingCounterID = id
  }
}

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @AppStorage(AppAppearancePreference.darkModeEnabledKey) private var isDarkModeEnabled = false
  @AppStorage(AppAppearancePreference.fpsCounterEnabledKey) private var isFPSCounterEnabled = false
  @AppStorage(FreshInstallOnboarding.hasCompletedKey) private var hasCompletedFreshInstall = true
  @AppStorage(FreshInstallOnboarding.previewActiveKey) private var isFreshInstallPreview = false
  @State private var isBootstrapped = false
  @State private var sheetCoordinator = CounterSheetCoordinator()
  @State private var focusRouter = CounterFocusRouter()

  private var showsFreshInstall: Bool {
    isBootstrapped && (!hasCompletedFreshInstall || isFreshInstallPreview)
  }

  private var showsPager: Bool {
    isBootstrapped && hasCompletedFreshInstall && !isFreshInstallPreview
  }

  var body: some View {
    ZStack {
      CounterPagerView()
        .environment(sheetCoordinator)
        .environment(focusRouter)
        .counterDesignSystemFromColorScheme()
        .opacity(showsPager ? 1 : 0)

      BootSplashView()
        .opacity(isBootstrapped ? 0 : 1)

      if showsFreshInstall {
        FreshInstallOnboardingView()
          .transition(.opacity)
      }

      CounterSheetHost(coordinator: sheetCoordinator)
    }
    .overlay(alignment: .bottomTrailing) {
      if isFPSCounterEnabled && showsPager {
        FPSCounterView()
          .counterDesignSystemFromColorScheme()
          .padding(.trailing, SpaceToken.pageMargin)
          .padding(.bottom, SpaceToken.pageFooterBottom)
      }
    }
    .animation(.easeOut(duration: 0.25), value: isBootstrapped)
    .animation(.easeOut(duration: 0.25), value: hasCompletedFreshInstall)
    .animation(.easeOut(duration: 0.25), value: isFreshInstallPreview)
    .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
    .onOpenURL { url in
      focusRouter.handle(url)
    }
    .task {
      WatchSyncCoordinator.shared.activate()
      FreshInstallOnboarding.migrateIfNeeded(
        hasCounters: SampleDataSeeder.hasAnyCounters(in: modelContext)
      )
      if FreshInstallOnboarding.hasCompleted {
        SampleDataSeeder.seedIfNeeded(in: modelContext)
      }
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
