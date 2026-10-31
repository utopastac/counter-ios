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
  /// Compact underlay tiles use a smaller ring/total and omit the subtitle.
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
          gridTile
            .padding(SpaceToken.componentPadding)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        } else {
          gridTile
            .padding(SpaceToken.u2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .aspectRatio(1, contentMode: .fit)
        }
      }
      .background(
        palette.backgroundStyle(for: colorScheme),
        in: RadiusToken.continuous(isCompact ? RadiusToken.compactListCard : CountersListGridToken.cornerRadius)
      )
      .counterAccent(accent)
    }
    .buttonStyle(.plain)
    .contentShape(Rectangle())
  }

  /// Ring on top, then title / total — mirrors the small home-screen widget. Compact tiles
  /// shrink the ring and total and drop the subtitle, hugging content height.
  private var gridTile: some View {
    VStack(alignment: .leading, spacing: 0) {
      if let ringProgress {
        GoalProgressRing(
          progress: ringProgress,
          size: isCompact ? CountersListGridToken.compactRingSize : SizeToken.Ring.gridTile,
          ringWidthOverride: ringWidthOverride,
          ringGlowOverride: ringGlowOverride,
          trackColor: palette.progressRingTrack(for: colorScheme),
          fillColor: palette.foreground(for: colorScheme)
        )
        .padding(
          .bottom,
          isCompact ? CountersListGridToken.compactRingToTitleSpacing : CountersListGridToken.ringToTitleSpacing
        )
      }

      Text(title)
        .counterTextStyle(.listCardTitle, compact: true)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .truncationMode(.tail)

      Text(value)
        .counterTextStyle(isCompact ? .listCardNumberCompact : .listCardNumber, compact: true)
        .minimumScaleFactor(0.6)
        .lineLimit(1)
        .padding(.top, CountersListGridToken.titleToValueSpacing)

      if !isCompact {
        Text(caption)
          .counterTextStyle(.listCardCaption, compact: true)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
          .padding(.top, CountersListGridToken.valueToSubtitleSpacing)

        Spacer(minLength: 0)
      }
    }
  }
}

#Preview {
  LazyVGrid(
    columns: Array(
      repeating: GridItem(.flexible(), spacing: CountersListGridToken.spacing),
      count: CountersListGridToken.columnCount
    ),
    spacing: CountersListGridToken.spacing
  ) {
    CounterListCard(
      accent: .forCustomCounter(at: 0),
      title: "Calories",
      value: "1800",
      caption: "420 remaining",
      ringProgress: GoalProgress(current: 1800, goal: 2200, direction: .countDown)
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
