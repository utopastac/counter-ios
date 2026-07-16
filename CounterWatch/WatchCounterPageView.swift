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

  private var theme: WatchThemeColors {
    let _ = (isMonoEnabled, monoPaletteIndex)
    return WatchThemeColors(
      paletteIndex: AppAppearancePreference.resolvedPaletteIndex(counter.effectivePaletteIndex)
    )
  }

  private var progress: GoalProgress? {
    counter.currentProgress()
  }

  var body: some View {
    ZStack {
      theme.background
        .ignoresSafeArea()

      VStack(spacing: 0) {
        header
          .padding(.horizontal, 8)
          .padding(.top, 4)

        Spacer(minLength: 0)

        hero
          .padding(.horizontal, 8)

        Spacer(minLength: 0)

        footer
          .padding(.horizontal, 8)
          .padding(.bottom, 8)
      }
    }
    .navigationBarHidden(true)
  }

  private var header: some View {
    HStack(alignment: .top, spacing: 8) {
      if let progress {
        WatchGoalProgressRing(progress: progress, theme: theme)
      } else {
        Color.clear
          .frame(width: 28, height: 28)
      }

      Spacer(minLength: 0)

      VStack(alignment: .trailing, spacing: 0) {
        TimelineView(.periodic(from: .now, by: 60)) { context in
          Text(context.date, style: .time)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .monospacedDigit()
        }
        Text(counter.name)
          .font(.system(size: 13, weight: .medium, design: .rounded))
          .foregroundStyle(theme.mutedForeground)
          .lineLimit(1)
      }
    }
  }

  private var hero: some View {
    VStack(spacing: 4) {
      Text(heroValue)
        .font(.system(size: 44, weight: .bold, design: .rounded))
        .foregroundStyle(theme.foreground)
        .minimumScaleFactor(0.5)
        .lineLimit(1)
        .contentTransition(.numericText())

      if let subtitle {
        Text(subtitle)
          .font(.system(size: 15, weight: .medium, design: .rounded))
          .foregroundStyle(theme.mutedForeground)
      }
    }
    .frame(maxWidth: .infinity)
  }

  private var footer: some View {
    HStack {
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

      Spacer(minLength: 0)
    }
  }

  private var heroValue: String {
    "\(counter.currentTotal())"
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
