import SwiftUI

struct CounterPageLayout<Footer: View, EntryLog: View>: View {
  @Environment(\.counterAccent) private var counterAccent
  @Environment(\.counterPagerAccents) private var pagerAccents
  @Environment(\.counterPagerScrollProgress) private var pagerScrollProgress
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
        pagerBackground

        VStack(alignment: .leading, spacing: 0) {
          Spacer()
            .frame(height: SpaceToken.pageTopInset)

          HStack(alignment: .center, spacing: SpaceToken.x4) {
            HeroMainNumberText(value: heroValue)
              .frame(maxWidth: .infinity, alignment: .leading)
              .layoutPriority(1)

            GoalProgressRing(
              progress: ringProgress,
              size: SizeToken.Ring.display,
              lineWidth: SizeToken.Ring.displayStroke,
              trackColor: ringPalette.progressRingTrack(for: colorScheme),
              fillColor: ringPalette.foreground(for: colorScheme)
            )
          }
          .padding(.top, SpaceToken.u2)

          if !statRows.isEmpty {
            CounterStatsTable(rows: statRows)
          }

          Spacer(minLength: 0)

          entryLog()
            .frame(maxWidth: .infinity, alignment: .bottomLeading)

          footer()
            .padding(.top, SpaceToken.x3)
            .padding(.bottom, SpaceToken.u1)
        }
        .padding(.horizontal, SpaceToken.pageMargin)
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
      }
    }
  }

  @ViewBuilder
  private var pagerBackground: some View {
    if let pagerAccents, let pagerScrollProgress {
      CounterPagerBackdrop(accents: pagerAccents, scrollProgress: pagerScrollProgress)
    } else {
      (counterAccent ?? .calories).palette.background(for: colorScheme)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}

/// Wraps pager page content in a navigation stack with a fully transparent chrome.
struct CounterPagerPageRoot<Content: View>: View {
  @ViewBuilder var content: () -> Content

  var body: some View {
    NavigationStack {
      ZStack {
        Color.clear
        content()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .toolbar(.hidden, for: .navigationBar)
    .toolbarBackground(.hidden, for: .navigationBar)
    .background {
      Color.clear
        .ignoresSafeArea()
    }
    .containerBackground(.clear, for: .navigation)
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
