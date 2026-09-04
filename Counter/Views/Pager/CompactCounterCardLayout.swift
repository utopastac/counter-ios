import SwiftUI

/// Compact-mode counter card — a shrunken, self-contained card (title, hero number,
/// ring, and quick-add footer). Tapping the hero number toggles the stats table when
/// a goal is set, matching the full-page layout.
struct CompactCounterCardLayout<Footer: View, Toast: View>: View {
  @Environment(\.counterAccent) private var counterAccent
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.counterRevealIsDragging) private var counterRevealIsDragging
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @AppStorage(
    AppAppearancePreference.tintEnabledKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var isTintEnabled = true
  @AppStorage(
    AppAppearancePreference.colorPackKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var colorPackRaw = CounterColorPack.muted.rawValue

  let title: String
  let heroValue: String
  let heroSubtitle: String?
  let statRows: [CounterStatRow]
  let ringProgress: GoalProgress?
  var ringWidthOverride: ProgressRingWidth? = nil
  var ringGlowOverride: Bool? = nil
  /// When true, open on the stats table (if expandable) instead of the big number.
  var startsWithStatsHeader: Bool = false
  let onShowHistory: () -> Void
  let onShowButtonSettings: () -> Void
  @ViewBuilder var footer: () -> Footer
  @ViewBuilder var toast: () -> Toast

  @State private var isHeaderExpanded: Bool

  private var canExpandHeader: Bool {
    statRows.count > 1
  }

  private var headerToggleAnimation: Animation {
    MotionToken.headerToggle(reduceMotion: reduceMotion)
  }

  private var palette: CounterPaletteSlot {
    let _ = (isTintEnabled, colorPackRaw)
    return (counterAccent ?? .forCustomCounter(at: 0)).palette
  }

  init(
    title: String,
    heroValue: String,
    heroSubtitle: String? = nil,
    statRows: [CounterStatRow] = [],
    ringProgress: GoalProgress? = nil,
    ringWidthOverride: ProgressRingWidth? = nil,
    ringGlowOverride: Bool? = nil,
    startsWithStatsHeader: Bool = false,
    onShowHistory: @escaping () -> Void,
    onShowButtonSettings: @escaping () -> Void,
    @ViewBuilder footer: @escaping () -> Footer,
    @ViewBuilder toast: @escaping () -> Toast
  ) {
    self.title = title
    self.heroValue = heroValue
    self.heroSubtitle = heroSubtitle
    self.statRows = statRows
    self.ringProgress = ringProgress
    self.ringWidthOverride = ringWidthOverride
    self.ringGlowOverride = ringGlowOverride
    self.startsWithStatsHeader = startsWithStatsHeader
    self.onShowHistory = onShowHistory
    self.onShowButtonSettings = onShowButtonSettings
    self.footer = footer
    self.toast = toast
    self._isHeaderExpanded = State(
      initialValue: startsWithStatsHeader && statRows.count > 1
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      header
        .padding(.bottom, CompactCardToken.headerToHeroSpacing)

      heroRow
        .padding(.bottom, CompactCardToken.heroToFooterSpacing)
        .padding(.horizontal, CompactCardToken.cardPadding)

        footer()
          .padding(.horizontal, CompactCardToken.cardPadding)
          .padding(.bottom, CompactCardToken.cardPadding)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(palette.backgroundStyle(for: colorScheme), in: RadiusToken.continuous(RadiusToken.compactCard))
    .overlay(alignment: .topLeading) {
      toast()
        .fixedSize()
        .padding(.top, CompactCardToken.toastTopOffset)
        .padding(.leading, CompactCardToken.toastLeadingOffset)
    }
    .allowsHitTesting(!counterRevealIsDragging)
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
    .simultaneousGesture(
      LongPressGesture(minimumDuration: 0.45).onEnded { _ in
        guard !counterRevealIsDragging else { return }
        AppHaptics.impact()
        onShowHistory()
      }
    )
  }

  private var header: some View {
    HStack(spacing: SpaceToken.u2) {
      Text(title)
        .counterTextStyle(.pageTitle, compact: true)
        .lineLimit(1)
        .truncationMode(.tail)
        .padding(.leading, CompactCardToken.cardPadding)

      Spacer(minLength: SpaceToken.u1)

      HStack(spacing: SpaceToken.toolbarIconSpacing) {
        CounterIconButton(icon: .chartBar, action: onShowHistory)
        CounterIconButton(icon: .slidersHorizontal, action: onShowButtonSettings)
      }
    }
  }

  private var heroRow: some View {
    HStack(alignment: .top, spacing: SpaceToken.u2) {
      Button {
        guard !counterRevealIsDragging else { return }
        guard canExpandHeader else { return }
        AppHaptics.impact()
        withAnimation(headerToggleAnimation) {
          isHeaderExpanded.toggle()
        }
      } label: {
        ZStack(alignment: .topLeading) {
          heroDisplay
            .counterHeaderToggle(
              .hero,
              isExpanded: isHeaderExpanded,
              reduceMotion: reduceMotion
            )
            .allowsHitTesting(!isHeaderExpanded)

          if canExpandHeader {
            CounterStatsTable(rows: statRows, isRevealed: isHeaderExpanded)
              .padding(.top, CounterPageToken.headerContentOffset)
              .counterHeaderToggle(
                .stats,
                isExpanded: isHeaderExpanded,
                reduceMotion: reduceMotion
              )
              .allowsHitTesting(isHeaderExpanded)
          }
        }
        .animation(headerToggleAnimation, value: isHeaderExpanded)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: CounterPageToken.headerContentHeight, alignment: .topLeading)
        .clipped()
        .contentShape(Rectangle())
      }
      .buttonStyle(.noHighlight)
      .disabled(!canExpandHeader)
      .layoutPriority(1)

      if let ringProgress {
        GoalProgressRing(
          progress: ringProgress,
          size: SizeToken.Ring.display,
          ringWidthOverride: ringWidthOverride,
          ringGlowOverride: ringGlowOverride,
          trackColor: palette.progressRingTrack(for: colorScheme),
          fillColor: palette.foreground(for: colorScheme)
        )
        .frame(width: SizeToken.Ring.display, height: CounterPageToken.heroBandHeight, alignment: .center)
        .padding(.top, CounterPageToken.headerContentOffset)
      }
    }
  }

  private var heroDisplay: some View {
    VStack(alignment: .leading, spacing: CounterPageToken.heroSubtitleSpacing) {
      Text(heroValue)
        .counterTextStyle(.mainNumber)
        .minimumScaleFactor(0.6)
        .lineLimit(1)
        .contentTransition(.numericText())
        .padding(.top, CompactCardToken.heroNumberLeadingTrim)

      if let heroSubtitle {
        Text(heroSubtitle)
          .counterTextStyle(.heroSubtitle)
          .lineLimit(1)
          .contentTransition(.numericText())
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .offset(y: CompactCardToken.heroTextRingOpticalOffset)
  }
}

extension CompactCounterCardLayout where Toast == EmptyView {
  init(
    title: String,
    heroValue: String,
    heroSubtitle: String? = nil,
    statRows: [CounterStatRow] = [],
    ringProgress: GoalProgress? = nil,
    ringWidthOverride: ProgressRingWidth? = nil,
    ringGlowOverride: Bool? = nil,
    startsWithStatsHeader: Bool = false,
    onShowHistory: @escaping () -> Void,
    onShowButtonSettings: @escaping () -> Void,
    @ViewBuilder footer: @escaping () -> Footer
  ) {
    self.init(
      title: title,
      heroValue: heroValue,
      heroSubtitle: heroSubtitle,
      statRows: statRows,
      ringProgress: ringProgress,
      ringWidthOverride: ringWidthOverride,
      ringGlowOverride: ringGlowOverride,
      startsWithStatsHeader: startsWithStatsHeader,
      onShowHistory: onShowHistory,
      onShowButtonSettings: onShowButtonSettings,
      footer: footer,
      toast: { EmptyView() }
    )
  }
}
