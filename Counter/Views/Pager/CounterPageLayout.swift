import SwiftUI

struct CounterPageLayout<Footer: View, EntryLog: View>: View {
  @Environment(\.counterAccent) private var counterAccent
  @Environment(\.counterPagerAccents) private var pagerAccents
  @Environment(\.counterPagerScrollProgress) private var pagerScrollProgress
  @Environment(\.counterPagerIsDragging) private var counterPagerIsDragging
  @Environment(\.colorScheme) private var colorScheme

  let heroValue: String
  let heroSubtitle: String?
  let statRows: [CounterStatRow]
  let ringProgress: GoalProgress
  @ViewBuilder var entryLog: () -> EntryLog
  @ViewBuilder var footer: () -> Footer

  @State private var isHeaderExpanded = false

  private var ringPalette: CounterPaletteSlot {
    (counterAccent ?? .forCustomCounter(at: 0)).palette
  }

  private var canExpandHeader: Bool {
    statRows.count > 1
  }

  init(
    heroValue: String,
    heroSubtitle: String? = nil,
    statRows: [CounterStatRow],
    ringProgress: GoalProgress,
    @ViewBuilder entryLog: @escaping () -> EntryLog,
    @ViewBuilder footer: @escaping () -> Footer
  ) {
    self.heroValue = heroValue
    self.heroSubtitle = heroSubtitle
    self.statRows = statRows
    self.ringProgress = ringProgress
    self.entryLog = entryLog
    self.footer = footer
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        pagerBackground

        VStack(alignment: .leading, spacing: 0) {
          Spacer()
            .frame(height: SpaceToken.pageTopInset)

          CounterPageHeader(
            heroValue: heroValue,
            heroSubtitle: heroSubtitle,
            statRows: statRows,
            ringProgress: ringProgress,
            ringPalette: ringPalette,
            isExpanded: $isHeaderExpanded,
            canExpand: canExpandHeader
          )
          .padding(.top, SpaceToken.u2)

          footer()
            .padding(.top, CounterPageToken.statsToQuickActionsSpacing)

          Spacer(minLength: 0)

          entryLog()
            .frame(maxWidth: .infinity, alignment: .bottomLeading)
            .padding(.bottom, SpaceToken.u3)
        }
        .padding(.horizontal, SpaceToken.pageMargin)
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        .allowsHitTesting(!counterPagerIsDragging)
      }
    }
  }

  @ViewBuilder
  private var pagerBackground: some View {
    if let pagerAccents, let pagerScrollProgress {
      CounterPagerBackdrop(accents: pagerAccents, scrollProgress: pagerScrollProgress)
    } else {
      (counterAccent ?? .forCustomCounter(at: 0)).palette.background(for: colorScheme)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}

/// Wraps pager page content without navigation chrome so system overlays stay visible.
struct CounterPagerPageRoot<Content: View>: View {
  @ViewBuilder var content: () -> Content

  var body: some View {
    ZStack {
      Color.clear
      content()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .homeIndicatorAlwaysVisible()
  }
}

private struct CounterPageHeader: View {
  @Environment(\.colorScheme) private var colorScheme

  let heroValue: String
  let heroSubtitle: String?
  let statRows: [CounterStatRow]
  let ringProgress: GoalProgress
  let ringPalette: CounterPaletteSlot
  @Binding var isExpanded: Bool
  let canExpand: Bool

  private var contentHeight: CGFloat {
    CounterPageToken.headerContentHeight
  }

  var body: some View {
    HStack(alignment: .top, spacing: SpaceToken.u4) {
      Button {
        guard canExpand else { return }
        withAnimation(CounterPageToken.headerToggleAnimation) {
          isExpanded.toggle()
        }
      } label: {
        ZStack(alignment: .topLeading) {
          HeroSimpleDisplay(value: heroValue, subtitle: heroSubtitle)
            .opacity(isExpanded ? 0 : 1)
            .allowsHitTesting(!isExpanded)

          if canExpand {
            CounterStatsTable(rows: statRows)
              .padding(.top, CounterPageToken.headerContentOffset)
              .opacity(isExpanded ? 1 : 0)
              .allowsHitTesting(isExpanded)
          }
        }
        .animation(CounterPageToken.headerToggleAnimation, value: isExpanded)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: contentHeight, alignment: .topLeading)
        .clipped()
        .contentShape(Rectangle())
      }
      .buttonStyle(.noHighlight)
      .disabled(!canExpand)
      .layoutPriority(1)

      GoalProgressRing(
        progress: ringProgress,
        size: SizeToken.Ring.display,
        lineWidth: SizeToken.Ring.displayStroke,
        trackColor: ringPalette.progressRingTrack(for: colorScheme),
        fillColor: ringPalette.foreground(for: colorScheme)
      )
      .frame(width: SizeToken.Ring.display, height: CounterPageToken.heroBandHeight, alignment: .center)
      .padding(.top, CounterPageToken.headerContentOffset)
    }
    .frame(height: contentHeight, alignment: .top)
  }
}

private struct HeroSimpleDisplay: View {
  let value: String
  let subtitle: String?

  var body: some View {
    VStack(alignment: .leading, spacing: CounterPageToken.heroSubtitleSpacing) {
      HeroMainNumberText(value: value)

      if let subtitle {
        HeroSubtitleText(text: subtitle)
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

private struct HeroSubtitleText: View {
  let text: String

  var body: some View {
    Text(text)
      .counterTextStyle(.heroSubtitle)
      .lineLimit(1)
      .contentTransition(.numericText())
  }
}

extension CounterPageLayout where EntryLog == EmptyView {
  init(
    heroValue: String,
    heroSubtitle: String? = nil,
    statRows: [CounterStatRow],
    ringProgress: GoalProgress,
    @ViewBuilder footer: @escaping () -> Footer
  ) {
    self.init(
      heroValue: heroValue,
      heroSubtitle: heroSubtitle,
      statRows: statRows,
      ringProgress: ringProgress,
      entryLog: { EmptyView() },
      footer: footer
    )
  }
}
