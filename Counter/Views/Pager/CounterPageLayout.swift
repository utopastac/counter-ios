import SwiftUI

struct CounterPageLayout<Footer: View, EntryLog: View>: View {
  @Environment(\.counterAccent) private var counterAccent
  @Environment(\.colorScheme) private var colorScheme

  let heroValue: String
  let statRows: [CounterStatRow]
  let ringProgress: GoalProgress
  @ViewBuilder var entryLog: () -> EntryLog
  @ViewBuilder var footer: () -> Footer

  private var ringPalette: CounterPaletteSlot {
    (counterAccent ?? .calories).palette
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        CounterPageBackground()

        VStack(alignment: .leading, spacing: 0) {
          Spacer()
            .frame(height: SpaceToken.pageTopInset)

          HStack(alignment: .center, spacing: SpaceToken.x4) {
            HeroMainNumberText(value: heroValue)
              .frame(maxWidth: .infinity, minHeight: FontSizeToken.x5xl, alignment: .leading)
              .layoutPriority(1)

            GoalProgressRing(
              progress: ringProgress,
              size: SizeToken.Ring.display,
              lineWidth: SizeToken.Ring.displayStroke,
              trackColor: ringPalette.progressRingTrack(for: colorScheme),
              fillColor: ringPalette.foreground(for: colorScheme)
            )
          }

          if !statRows.isEmpty {
            CounterStatsTable(rows: statRows)
              .padding(.top, SpaceToken.x5)
          }

          Spacer(minLength: 0)

          entryLog()
            .frame(maxWidth: .infinity, alignment: .bottomLeading)

          footer()
            .padding(.top, SpaceToken.x3)
            .padding(.bottom, SpaceToken.pageFooterBottom)
        }
        .padding(.horizontal, SpaceToken.pageMargin)
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
      }
    }
  }
}

private struct HeroMainNumberText: View {
  let value: String

  var body: some View {
    Text(value)
      .counterTextStyle(.mainNumber)
      .minimumScaleFactor(0.6)
      .lineLimit(1)
      .fixedSize(horizontal: false, vertical: true)
      .contentTransition(.numericText())
  }
}

extension CounterPageLayout where EntryLog == EmptyView {
  init(
    heroValue: String,
    statRows: [CounterStatRow],
    ringProgress: GoalProgress,
    @ViewBuilder footer: @escaping () -> Footer
  ) {
    self.heroValue = heroValue
    self.statRows = statRows
    self.ringProgress = ringProgress
    self.entryLog = { EmptyView() }
    self.footer = footer
  }
}

struct PagerDotIndicator: View {
  @Environment(\.semanticColors) private var colors

  let labels: [String]
  let selectedIndex: Int

  var body: some View {
    HStack {
      Spacer()

      VStack(spacing: SpaceToken.x2) {
        ForEach(labels.indices, id: \.self) { index in
          Capsule()
            .fill(index == selectedIndex ? colors.textPrimary : colors.textDisabled)
            .frame(width: index == selectedIndex ? 6 : 5, height: index == selectedIndex ? 18 : 5)
            .animation(.easeInOut(duration: MotionToken.pagerDotDuration), value: selectedIndex)
        }
      }
      .padding(.horizontal, 10)
      .padding(.vertical, SpaceToken.x3 + 2)
      .background {
        Capsule()
          .fill(colors.textPrimary.opacity(0.08))
      }
      .padding(.trailing, SpaceToken.x4)
    }
    .allowsHitTesting(false)
  }
}
