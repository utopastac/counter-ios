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
  @AppStorage(FreshInstallOnboarding.hasCompletedKey) private var hasCompletedFreshInstall = true
#if DEBUG
  @AppStorage(AppAppearancePreference.fpsCounterEnabledKey) private var isFPSCounterEnabled = false
  @AppStorage(FreshInstallOnboarding.previewActiveKey) private var isFreshInstallPreview = false
#endif
  @State private var isBootstrapped = false
  @State private var sheetCoordinator = CounterSheetCoordinator()
  @State private var focusRouter = CounterFocusRouter()

  private var showsFreshInstall: Bool {
#if DEBUG
    isBootstrapped && (!hasCompletedFreshInstall || isFreshInstallPreview)
#else
    isBootstrapped && !hasCompletedFreshInstall
#endif
  }

  private var showsPager: Bool {
#if DEBUG
    isBootstrapped && hasCompletedFreshInstall && !isFreshInstallPreview
#else
    isBootstrapped && hasCompletedFreshInstall
#endif
  }

  /// Seeds fake counters + history and focuses Calories when the scene needs it.
  /// Onboarding scene clears the store instead so the fresh-install flow can run.
  private func prepareUITestingLaunch() {
    if UITesting.showsOnboarding {
      clearAllCountersForUITesting()
      return
    }

    ScreenshotDataSeeder.replaceAll(in: modelContext)
    if UITesting.shouldFocusPrimaryCounter {
      focusRouter.pendingCounterID = ScreenshotDataSeeder.caloriesID
    }
  }

  private func clearAllCountersForUITesting() {
    for counter in (try? modelContext.fetch(FetchDescriptor<CustomCounter>())) ?? [] {
      modelContext.delete(counter)
    }
    AppLog.attempt("Clear store for onboarding UI test") { try modelContext.save() }
  }

  var body: some View {
    ZStack {
      if UITesting.showsWidgetGallery {
        ScreenshotWidgetsGalleryView()
          .counterDesignSystemFromColorScheme()
          .opacity(isBootstrapped ? 1 : 0)
      } else {
        // Unmount the pager when onboarding is up so reset-all / wipe can't leave
        // SwiftUI reading invalidated `@Model` instances behind an opacity-0 tree.
        if showsPager {
          CounterPagerView()
            .environment(sheetCoordinator)
            .environment(focusRouter)
            .counterDesignSystemFromColorScheme()
        }

        if showsFreshInstall {
          FreshInstallOnboardingView()
            .transition(.opacity)
        }

        CounterSheetHost(coordinator: sheetCoordinator)
      }

      BootSplashView()
        .opacity(isBootstrapped ? 0 : 1)
    }
#if DEBUG
    .overlay(alignment: .bottomTrailing) {
      if isFPSCounterEnabled && showsPager {
        FPSCounterView()
          .counterDesignSystemFromColorScheme()
          .padding(.trailing, SpaceToken.pageMargin)
          .padding(.bottom, SpaceToken.pageFooterBottom)
      }
    }
#endif
    .animation(.easeOut(duration: 0.25), value: isBootstrapped)
    .animation(.easeOut(duration: 0.25), value: hasCompletedFreshInstall)
#if DEBUG
    .animation(.easeOut(duration: 0.25), value: isFreshInstallPreview)
#endif
    .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
    .onOpenURL { url in
      focusRouter.handle(url)
    }
    .onChange(of: showsFreshInstall) { _, isShowing in
      guard isShowing else { return }
      // Wipe only after the pager has left the tree. Even with animations disabled,
      // wait a turn so AttributeGraph finishes tearing down counter pages.
      Task { @MainActor in
        await Task.yield()
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(50))
        AppDataReset.performPendingWipeIfNeeded(in: modelContext)
      }
    }
    .task {
      if UITesting.isEnabled {
        prepareUITestingLaunch()
        isBootstrapped = true
        return
      }

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
