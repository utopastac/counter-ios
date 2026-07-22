import SwiftUI

/// Compact-mode counter card — a shrunken, self-contained card (title, hero number,
/// ring, and quick-add footer). Row entries are never shown inline; tapping the
/// header's logs icon opens the entry log modal sheet instead.
struct CompactCounterCardLayout<Footer: View, Toast: View>: View {
  @Environment(\.counterAccent) private var counterAccent
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.counterRevealIsDragging) private var counterRevealIsDragging
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
  let ringProgress: GoalProgress?
  let onSelectEntryLog: () -> Void
  let onShowHistory: () -> Void
  let onShowButtonSettings: () -> Void
  @ViewBuilder var footer: () -> Footer
  @ViewBuilder var toast: () -> Toast

  private var palette: CounterPaletteSlot {
    let _ = (isTintEnabled, colorPackRaw)
    return (counterAccent ?? .forCustomCounter(at: 0)).palette
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
    .background(palette.background(for: colorScheme), in: RadiusToken.continuous(RadiusToken.compactCard))
    .overlay(alignment: .top) {
      toast()
        .fixedSize()
        .padding(.top, CompactCardToken.toastTopOffset)
    }
    .allowsHitTesting(!counterRevealIsDragging)
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
        CounterIconButton(icon: .logs, action: onSelectEntryLog)
        CounterIconButton(icon: .chartBar, action: onShowHistory)
        CounterIconButton(icon: .slidersHorizontal, action: onShowButtonSettings)
      }
    }
  }

  private var heroRow: some View {
    HStack(alignment: .center, spacing: SpaceToken.u2) {
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

      if let ringProgress {
        GoalProgressRing(
          progress: ringProgress,
          size: SizeToken.Ring.display,
          trackColor: palette.progressRingTrack(for: colorScheme),
          fillColor: palette.foreground(for: colorScheme)
        )
      }
    }
  }
}

extension CompactCounterCardLayout where Toast == EmptyView {
  init(
    title: String,
    heroValue: String,
    heroSubtitle: String? = nil,
    ringProgress: GoalProgress? = nil,
    onSelectEntryLog: @escaping () -> Void,
    onShowHistory: @escaping () -> Void,
    onShowButtonSettings: @escaping () -> Void,
    @ViewBuilder footer: @escaping () -> Footer
  ) {
    self.init(
      title: title,
      heroValue: heroValue,
      heroSubtitle: heroSubtitle,
      ringProgress: ringProgress,
      onSelectEntryLog: onSelectEntryLog,
      onShowHistory: onShowHistory,
      onShowButtonSettings: onShowButtonSettings,
      footer: footer,
      toast: { EmptyView() }
    )
  }
}
