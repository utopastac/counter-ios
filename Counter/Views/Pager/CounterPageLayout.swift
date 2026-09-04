import SwiftUI

struct CounterPageLayout<Footer: View, EntryLog: View, Toast: View>: View {
  @Environment(\.counterAccent) private var counterAccent
  @Environment(\.counterPagerAccents) private var pagerAccents
  @Environment(\.counterPagerScrollState) private var pagerScrollState
  @Environment(\.counterRevealIsDragging) private var counterRevealIsDragging
  @Environment(\.colorScheme) private var colorScheme
  @AppStorage(
    AppAppearancePreference.tintEnabledKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var isTintEnabled = true
  @AppStorage(
    AppAppearancePreference.colorPackKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var colorPackRaw = CounterColorPack.muted.rawValue

  let heroValue: String
  let heroSubtitle: String?
  let statRows: [CounterStatRow]
  let ringProgress: GoalProgress?
  var ringWidthOverride: ProgressRingWidth? = nil
  var ringGlowOverride: Bool? = nil
  /// When true, open on the stats table (if expandable) instead of the big number.
  var startsWithStatsHeader: Bool = false
  @ViewBuilder var entryLog: () -> EntryLog
  @ViewBuilder var footer: () -> Footer
  @ViewBuilder var toast: () -> Toast

  @State private var isHeaderExpanded: Bool

  private var ringPalette: CounterPaletteSlot {
    let _ = (isTintEnabled, colorPackRaw)
    return (counterAccent ?? .forCustomCounter(at: 0)).palette
  }

  private var canExpandHeader: Bool {
    statRows.count > 1
  }

  init(
    heroValue: String,
    heroSubtitle: String? = nil,
    statRows: [CounterStatRow],
    ringProgress: GoalProgress? = nil,
    ringWidthOverride: ProgressRingWidth? = nil,
    ringGlowOverride: Bool? = nil,
    startsWithStatsHeader: Bool = false,
    @ViewBuilder entryLog: @escaping () -> EntryLog,
    @ViewBuilder footer: @escaping () -> Footer,
    @ViewBuilder toast: @escaping () -> Toast
  ) {
    self.heroValue = heroValue
    self.heroSubtitle = heroSubtitle
    self.statRows = statRows
    self.ringProgress = ringProgress
    self.ringWidthOverride = ringWidthOverride
    self.ringGlowOverride = ringGlowOverride
    self.startsWithStatsHeader = startsWithStatsHeader
    self.entryLog = entryLog
    self.footer = footer
    self.toast = toast
    self._isHeaderExpanded = State(
      initialValue: startsWithStatsHeader && statRows.count > 1
    )
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
            ringWidthOverride: ringWidthOverride,
            ringGlowOverride: ringGlowOverride,
            ringPalette: ringPalette,
            isExpanded: $isHeaderExpanded,
            canExpand: canExpandHeader
          )
          .padding(.top, SpaceToken.u2)
          .onChange(of: startsWithStatsHeader) { _, wantsStats in
            isHeaderExpanded = wantsStats && canExpandHeader
          }
          .onChange(of: canExpandHeader) { _, canExpand in
            if !canExpand {
              isHeaderExpanded = false
            } else if startsWithStatsHeader {
              isHeaderExpanded = true
            }
          }

          footer()
            .padding(.top, CounterPageToken.statsToQuickActionsSpacing)

          Spacer(minLength: 0)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .top) {
              toast()
                .fixedSize()
                .padding(.top, CounterPageToken.toastTopOffset)
                .frame(maxWidth: .infinity)
            }

          entryLog()
            .frame(maxWidth: .infinity, alignment: .bottomLeading)
            .padding(.bottom, CounterPageToken.entryLogBottomInset)
        }
        .padding(.horizontal, SpaceToken.pageMargin)
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        .allowsHitTesting(!(pagerScrollState?.isDragging ?? false) && !counterRevealIsDragging)
      }
    }
  }

  @ViewBuilder
  private var pagerBackground: some View {
    if let pagerAccents, let pagerScrollState {
      PagerBackdropView(accents: pagerAccents, scrollState: pagerScrollState)
    } else {
      Rectangle()
        .fill(
          (counterAccent ?? .forCustomCounter(at: 0)).palette.backgroundStyle(for: colorScheme)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}

/// Wraps pager page content without navigation chrome.
struct CounterPagerPageRoot<Content: View>: View {
  @ViewBuilder var content: () -> Content

  var body: some View {
    ZStack {
      Color.clear
      content()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

private struct CounterPageHeader: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.counterRevealIsDragging) private var counterRevealIsDragging
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let heroValue: String
  let heroSubtitle: String?
  let statRows: [CounterStatRow]
  let ringProgress: GoalProgress?
  var ringWidthOverride: ProgressRingWidth? = nil
  var ringGlowOverride: Bool? = nil
  let ringPalette: CounterPaletteSlot
  @Binding var isExpanded: Bool
  let canExpand: Bool

  private var contentHeight: CGFloat {
    CounterPageToken.headerContentHeight
  }

  private var toggleAnimation: Animation {
    MotionToken.headerToggle(reduceMotion: reduceMotion)
  }

  var body: some View {
    HStack(alignment: .top, spacing: SpaceToken.u4) {
      Button {
        guard !counterRevealIsDragging else { return }
        guard canExpand else { return }
        AppHaptics.impact()
        withAnimation(toggleAnimation) {
          isExpanded.toggle()
        }
      } label: {
        ZStack(alignment: .topLeading) {
          HeroSimpleDisplay(value: heroValue, subtitle: heroSubtitle)
            .offset(y: CounterPageToken.heroTextOpticalOffset)
            .counterHeaderToggle(.hero, isExpanded: isExpanded, reduceMotion: reduceMotion)
            .allowsHitTesting(!isExpanded)

          if canExpand {
            CounterStatsTable(rows: statRows, isRevealed: isExpanded)
              .padding(.top, CounterPageToken.headerContentOffset)
              .counterHeaderToggle(.stats, isExpanded: isExpanded, reduceMotion: reduceMotion)
              .allowsHitTesting(isExpanded)
          }
        }
        .animation(toggleAnimation, value: isExpanded)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: contentHeight, alignment: .topLeading)
        .clipped()
        .contentShape(Rectangle())
      }
      .buttonStyle(.noHighlight)
      .disabled(!canExpand)
      .layoutPriority(1)

      if let ringProgress {
        GoalProgressRing(
          progress: ringProgress,
          size: SizeToken.Ring.display,
          ringWidthOverride: ringWidthOverride,
          ringGlowOverride: ringGlowOverride,
          trackColor: ringPalette.progressRingTrack(for: colorScheme),
          fillColor: ringPalette.foreground(for: colorScheme)
        )
        .frame(width: SizeToken.Ring.display, height: CounterPageToken.heroBandHeight, alignment: .center)
        .padding(.top, CounterPageToken.headerContentOffset)
      }
    }
    .frame(height: contentHeight, alignment: .top)
  }
}

private struct HeroSimpleDisplay: View {
  let value: String
  let subtitle: String?

  var body: some View {
    VStack(alignment: .leading, spacing: CounterPageToken.heroSubtitleSpacing) {
      Text(value)
        .counterTextStyle(.mainNumber)
        .minimumScaleFactor(0.6)
        .lineLimit(1)
        .fixedSize(horizontal: false, vertical: true)
        .contentTransition(.numericText())

      if let subtitle {
        Text(subtitle)
          .counterTextStyle(.heroSubtitle)
          .lineLimit(1)
          .contentTransition(.numericText())
      }
    }
  }
}

extension CounterPageLayout where EntryLog == EmptyView, Toast == EmptyView {
  init(
    heroValue: String,
    heroSubtitle: String? = nil,
    statRows: [CounterStatRow],
    ringProgress: GoalProgress? = nil,
    @ViewBuilder footer: @escaping () -> Footer
  ) {
    self.init(
      heroValue: heroValue,
      heroSubtitle: heroSubtitle,
      statRows: statRows,
      ringProgress: ringProgress,
      entryLog: { EmptyView() },
      footer: footer,
      toast: { EmptyView() }
    )
  }
}

extension CounterPageLayout where Toast == EmptyView {
  init(
    heroValue: String,
    heroSubtitle: String? = nil,
    statRows: [CounterStatRow],
    ringProgress: GoalProgress? = nil,
    @ViewBuilder entryLog: @escaping () -> EntryLog,
    @ViewBuilder footer: @escaping () -> Footer
  ) {
    self.init(
      heroValue: heroValue,
      heroSubtitle: heroSubtitle,
      statRows: statRows,
      ringProgress: ringProgress,
      entryLog: entryLog,
      footer: footer,
      toast: { EmptyView() }
    )
  }
}
