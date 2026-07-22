import SwiftUI

struct CounterListCard: View {
  @Environment(\.colorScheme) private var colorScheme
  @AppStorage(
    AppAppearancePreference.tintEnabledKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var isTintEnabled = true
  @AppStorage(
    AppAppearancePreference.colorPackKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var colorPackRaw = CounterColorPack.muted.rawValue

  let accent: CounterAccent
  let title: String
  let value: String
  let caption: String
  let ringProgress: GoalProgress?
  var ringWidthOverride: ProgressRingWidth? = nil
  var ringGlowOverride: Bool? = nil
  /// Single-line title · value · ring row used by the underlay list when compact mode is on.
  var isCompact = false
  let action: () -> Void

  private var palette: CounterPaletteSlot {
    let _ = (isTintEnabled, colorPackRaw)
    return accent.palette
  }

  var body: some View {
    Button(action: action) {
      Group {
        if isCompact {
          compactRow
        } else {
          standardRow
        }
      }
      .padding(.horizontal, SpaceToken.componentPadding)
      .padding(.vertical, SpaceToken.componentPadding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        palette.backgroundStyle(for: colorScheme),
        in: RadiusToken.continuous(isCompact ? RadiusToken.compactListCard : RadiusToken.listCard)
      )
      .counterAccent(accent)
    }
    .buttonStyle(.plain)
    .contentShape(Rectangle())
  }

  /// Title, value, and caption stacked on the leading edge with the ring trailing —
  /// the default underlay list row when compact mode is off.
  private var standardRow: some View {
    HStack(alignment: .center, spacing: SpaceToken.u1) {
      VStack(alignment: .leading, spacing: -SpaceToken.x1) {
        Text(title)
          .counterTextStyle(.listCardTitle, compact: true)
          .lineLimit(1)
          .truncationMode(.tail)
          .frame(maxWidth: .infinity, alignment: .leading)

        Text(value)
          .counterTextStyle(.listCardNumber, compact: true)
          .minimumScaleFactor(0.7)
          .lineLimit(1)

        Text(caption)
          .counterTextStyle(.listCardCaption, compact: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      if let ringProgress {
        GoalProgressRing(
          progress: ringProgress,
          size: SizeToken.Ring.card,
          ringWidthOverride: ringWidthOverride,
          ringGlowOverride: ringGlowOverride,
          trackColor: palette.progressRingTrack(for: colorScheme),
          fillColor: palette.foreground(for: colorScheme)
        )
      }
    }
  }

  /// Single-line row: ring leading, title, value trailing — matches the compact-mode
  /// underlay list mockup (no caption, 30pt ring, rounder corners).
  private var compactRow: some View {
    HStack(alignment: .center, spacing: SpaceToken.u1) {
      if let ringProgress {
        GoalProgressRing(
          progress: ringProgress,
          size: CompactCardToken.listRingSize,
          ringWidthOverride: ringWidthOverride,
          ringGlowOverride: ringGlowOverride,
          trackColor: palette.progressRingTrack(for: colorScheme),
          fillColor: palette.foreground(for: colorScheme)
        )
      }

      Text(title)
        .counterTextStyle(.listCardTitle, compact: true)
        .lineLimit(1)
        .truncationMode(.tail)

      Spacer(minLength: SpaceToken.u1)

      Text(value)
        .counterTextStyle(.listCardNumberCompact, compact: true)
        .minimumScaleFactor(0.7)
        .lineLimit(1)
    }
  }
}

#Preview {
  VStack(spacing: SpaceToken.x4) {
    CounterListCard(
      accent: .forCustomCounter(at: 0),
      title: "Calories",
      value: "1800",
      caption: "420 remaining",
      ringProgress: GoalProgress(current: 1800, goal: 2200, direction: .countDown)
    ) {}

    CounterListCard(
      accent: .forCustomCounter(at: 0),
      title: "Calories",
      value: "2424",
      caption: "80 remaining",
      ringProgress: GoalProgress(current: 2424, goal: 2504, direction: .countDown),
      isCompact: true
    ) {}

    CounterListCard(
      accent: .forCustomCounter(at: 1),
      title: "Protein",
      value: "80",
      caption: "70 to go",
      ringProgress: GoalProgress(current: 80, goal: 150, direction: .countUp),
      isCompact: true
    ) {}
  }
  .padding()
  .background(Color.black)
}
