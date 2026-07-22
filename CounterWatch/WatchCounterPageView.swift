import SwiftUI
import SwiftData

struct WatchCounterPageView: View {
  @Bindable var counter: CustomCounter
  @AppStorage(
    AppAppearancePreference.monoEnabledKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var isMonoEnabled = false
  @AppStorage(
    AppAppearancePreference.monoPaletteIndexKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var monoPaletteIndex = 0
  @AppStorage(
    AppAppearancePreference.tintEnabledKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var isTintEnabled = true
  @AppStorage(
    AppAppearancePreference.colorPackKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var colorPackRaw = CounterColorPack.muted.rawValue
  @AppStorage(
    AppAppearancePreference.progressRingWidthKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var ringWidthRaw = ProgressRingWidth.balanced.rawValue
  @AppStorage(
    AppAppearancePreference.progressRingGlowEnabledKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var ringGlowEnabled = false

  private var theme: WatchThemeColors {
    let _ = (
      isMonoEnabled, monoPaletteIndex, isTintEnabled, colorPackRaw, ringWidthRaw,
      ringGlowEnabled
    )
    return WatchThemeColors(
      paletteIndex: AppAppearancePreference.resolvedPaletteIndex(counter.effectivePaletteIndex)
    )
  }

  private var progress: GoalProgress? {
    counter.currentProgress()
  }

  var body: some View {
    ZStack {
      Rectangle()
        .fill(theme.backgroundStyle)
        .ignoresSafeArea()

      VStack(alignment: .leading, spacing: 0) {
        ring

        content
          .padding(.top, 10)

        Spacer(minLength: 0)
      }
      .padding(.leading, 8)
      .padding(.trailing, 12)
    }
    .navigationBarHidden(true)
  }

  private var ring: some View {
    Group {
      if let progress {
        let ringSize: CGFloat = 64
        let width = counter.overrideProgressRingWidth ?? AppAppearancePreference.progressRingWidth
        WatchGoalProgressRing(
          progress: progress,
          theme: theme,
          size: ringSize,
          lineWidth: width.strokeWidth(for: ringSize),
          ringGlowEnabled: counter.overrideProgressRingGlow
            ?? AppAppearancePreference.isProgressRingGlowEnabled
        )
      } else {
        Color.clear
          .frame(width: 64, height: 64)
      }
    }
  }

  private var content: some View {
    HStack(alignment: .center, spacing: 8) {
      hero

      Spacer(minLength: 0)

      quickAddButton
    }
  }

  private var hero: some View {
    VStack(alignment: .leading, spacing: -4) {
      Text(counter.name)
        .font(.system(size: 17, weight: .semibold, design: .rounded))
        .foregroundStyle(theme.foreground)
        .lineLimit(1)
        .minimumScaleFactor(0.7)

      Text(heroValue)
        .font(.system(size: 44, weight: .semibold, design: .rounded))
        .foregroundStyle(theme.foreground)
        .minimumScaleFactor(0.5)
        .lineLimit(1)
        .contentTransition(.numericText())
        .padding(.top, -2)

      if let subtitle {
        Text(subtitle)
          .font(.system(size: 16, weight: .semibold, design: .rounded))
          .foregroundStyle(theme.mutedForeground)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
      }
    }
  }

  private var quickAddButton: some View {
    NavigationLink {
      WatchQuickAddView(counter: counter)
    } label: {
      Image(systemName: "plus")
        .font(.system(size: 22, weight: .semibold))
        .foregroundStyle(theme.foreground)
        .frame(width: 44, height: 44)
        .background(theme.foreground.opacity(0.18), in: Circle())
    }
    .buttonStyle(.plain)
  }

  private var heroValue: String {
    if let progress {
      switch progress.direction {
      case .countUp:
        return progress.compactHeroValue
      case .countDown:
        return progress.heroValue
      }
    }
    return CounterFormatting.amount(counter.currentTotal())
  }

  private var subtitle: String? {
    guard let progress else { return nil }
    return progress.heroSubtitle
  }
}

#Preview {
  NavigationStack {
    WatchCounterPageView(counter: CustomCounter(name: "Calories", goal: 2200, goalDirection: .countDown))
  }
  .modelContainer(for: [CustomCounter.self, CounterEntry.self], inMemory: true)
}
