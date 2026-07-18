import SwiftUI

/// Layout tokens — spacing, radius, size, shadow.
/// Spacing and component sizes follow an **8pt base grid** — see `GridToken`.
enum GridToken {
  /// Base layout grid unit. Prefer multiples of 8pt for spacing and sizing.
  static let unit: CGFloat = 8

  static func units(_ count: Int) -> CGFloat {
    CGFloat(count) * unit
  }
}

/// Spacing on the 8pt grid — prefer `u1`…`u8` or semantic names (`pageMargin`, `componentPadding`).
enum SpaceToken {
  static let u1: CGFloat = GridToken.units(1)
  static let u2: CGFloat = GridToken.units(2)
  static let u3: CGFloat = GridToken.units(3)
  static let u4: CGFloat = GridToken.units(4)
  static let u7: CGFloat = GridToken.units(7)

  /// Page horizontal inset and default component padding (1 grid unit).
  static let pageMargin: CGFloat = u1
  static let componentPadding: CGFloat = u1

  /// Pager toolbar is flush to the card edges; icon-button hit areas provide the chrome.
  static let pageTopInset: CGFloat = SizeToken.iconButtonHitArea + BorderToken.toolbar
  static let pageFooterBottom: CGFloat = u7
  static let toolbarTop: CGFloat = u1
  static let toolbarBottom: CGFloat = u1
  /// Gap between adjacent icon-button frames (hit areas already provide glyph spacing).
  static let toolbarIconSpacing: CGFloat = 0

  /// Inset around the vertical counter pager card from the screen edge.
  static let scrollContainerInset: CGFloat = u1

  // Legacy aliases — map to grid multiples where possible.
  static let x1: CGFloat = u1 / 2
  static let x2: CGFloat = u1
  static let x3: CGFloat = u1 + x1
  static let x4: CGFloat = u2
  static let x5: CGFloat = u2 + x1
}

enum RadiusToken {
  static let xs: CGFloat = GridToken.units(1)
  static let sm: CGFloat = GridToken.unit * 1.5
  static let md: CGFloat = 14
  static let lg: CGFloat = 16
  static let xl: CGFloat = 18
  static let xxl: CGFloat = 28

  /// Standard corner radius for interactive buttons (8pt).
  static let button: CGFloat = xs

  /// Toggle track outer corners (8pt).
  static let toggle: CGFloat = 8

  /// Toggle thumb inner corners (4pt).
  static let toggleThumb: CGFloat = 4

  /// Counter list cards and matching list actions (12pt).
  static let listCard: CGFloat = sm

  /// Vertical counter pager card — fixed 16pt (2 grid units) corners.
  static let scrollContainer: CGFloat = SpaceToken.u2

  /// Compact-mode counter card corners.
  static let compactCard: CGFloat = xl

  static var continuousButton: RoundedRectangle {
    RoundedRectangle(cornerRadius: button, style: .continuous)
  }

  static var continuousListCard: RoundedRectangle {
    RoundedRectangle(cornerRadius: listCard, style: .continuous)
  }

  static func continuous(_ radius: CGFloat) -> RoundedRectangle {
    RoundedRectangle(cornerRadius: radius, style: .continuous)
  }
}

enum BorderToken {
  static let toolbar: CGFloat = 2
  static let statsRow: CGFloat = 0.5
  static let statsRowStrong: CGFloat = 3
  static let settingsDivider: CGFloat = 1
  static let colourSwatch: CGFloat = 2
}

enum EntryLogPreviewLimit {
  static let count = 5
}

enum SizeToken {
  /// Visual size of the icon glyph inside an icon button.
  static let iconButton: CGFloat = 24
  /// Layout and tap size for toolbar and header icon buttons (Apple HIG minimum).
  static let iconButtonHitArea: CGFloat = 44

  static let iconGlyph: CGFloat = 20
  static let quickAddHeight: CGFloat = 44
  static let tableRowHeight: CGFloat = GridToken.units(4)
  static let primaryButtonHeight: CGFloat = 56
  static let gridColumnCount: Int = 5
  static let gridSpacing: CGFloat = SpaceToken.x2
  static let toggleWidth: CGFloat = 64
  static let toggleHeight: CGFloat = 24
  static let toggleThumbPadding: CGFloat = 5
  static let toggleThumbWidth: CGFloat = 32
  static let toggleThumbHeight: CGFloat = 14

  enum Ring {
    /// Full counter page progress ring.
    static let display: CGFloat = 96
    /// Keeps a 25% stroke-to-size ratio (`displayStroke` / `display`).
    static let displayStroke: CGFloat = 24
    /// Mid-size ring for standard (non-compact) list cards.
    static let card: CGFloat = GridToken.units(8)
    static let cardStroke: CGFloat = 16
    static let `default`: CGFloat = display
    static let progressStroke: CGFloat = displayStroke
    static let overfillOutlineWidth: CGFloat = 2
  }
}

enum OpacityToken {
  static let iconButtonPressed: CGFloat = 0.5
  /// Primary action buttons when `isEnabled` is false.
  static let disabledButton: CGFloat = 0.5
}

enum MotionToken {
  static let iconButtonPressDuration: Double = 0.12

  static let pagerDotDuration: Double = 0.2
  static let revealSettleDuration: Double = 0.48
  static let revealSettleBounce: Double = 0.08
  static let reduceMotionDuration: Double = 0.22

  static var revealSettle: Animation {
    .smooth(duration: revealSettleDuration, extraBounce: revealSettleBounce)
  }

  static var reduceMotionSettle: Animation {
    .easeOut(duration: reduceMotionDuration)
  }

  static func settle(reduceMotion: Bool) -> Animation {
    reduceMotion ? reduceMotionSettle : revealSettle
  }

  static let entryInsertDuration: Double = 0.32
  static let entryInsertBounce: Double = 0.1

  static var entryInsert: Animation {
    .smooth(duration: entryInsertDuration, extraBounce: entryInsertBounce)
  }

  static let ringProgressDuration: Double = 0.38

  // No `extraBounce` here (unlike the other `.smooth` tokens above): the ring's fill fraction
  // is clamped at 0 and 1, so a spring overshooting past those bounds is invisible in one
  // direction but not the other — you'd see it reach 100% and then visibly recede before
  // settling back at full, reading as the ring animating backwards.
  static var ringProgress: Animation {
    .smooth(duration: ringProgressDuration)
  }

  static func ringProgress(reduceMotion: Bool) -> Animation? {
    reduceMotion ? nil : ringProgress
  }

  static func entryInsert(reduceMotion: Bool) -> Animation {
    reduceMotion ? reduceMotionSettle : entryInsert
  }

  static func entryRowTransition(reduceMotion: Bool) -> AnyTransition {
    if reduceMotion {
      return .opacity
    }
    return .asymmetric(
      insertion: .move(edge: .top).combined(with: .opacity),
      removal: .opacity
    )
  }
}

/// Counter pager page layout spacing.
enum CounterPageToken {
  /// Fixed header block height (15 grid units).
  static let headerContentHeight: CGFloat = GridToken.units(15)
  /// Height of the hero number band that the progress ring is centered within.
  static let heroBandHeight: CGFloat = max(TypeStyle.x5xlSemibold.lineHeight, SizeToken.Ring.display)
  /// Pulls the hero subtitle closer to the main number.
  static let heroSubtitleSpacing: CGFloat = -SpaceToken.u1
  /// Vertical offset for the ring and expanded stats table.
  static let headerContentOffset: CGFloat = SpaceToken.u1
  /// Gap between the header and quick-add actions (3 grid units).
  static let statsToQuickActionsSpacing: CGFloat = SpaceToken.u3
  /// Gap between quick-add actions and the entry-added toast (10 grid units).
  static let toastTopOffset: CGFloat = GridToken.units(10)
  /// Inset below the entry log preview and "All entries" control (2 grid units).
  static let entryLogBottomInset: CGFloat = SpaceToken.u2

  static let headerToggleAnimation: Animation = .spring(response: 0.38, dampingFraction: 0.86)
}

/// Compact-mode counter card — a shrunken, non-full-screen card with compressed spacing.
/// Row entries are hidden on-card and only shown via the entry log modal sheet.
enum CompactCardToken {
  /// Inner padding for compact card body content (hero + footer). Header icons are flush to the card edges.
  static let cardPadding: CGFloat = SpaceToken.u2
  /// Gap between stacked compact cards.
  static let cardSpacing: CGFloat = SpaceToken.u1
  /// Gap between the header row (title + icons) and the hero number row.
  static let headerToHeroSpacing: CGFloat = SpaceToken.u1
  /// Trims the `mainNumber` font's built-in leading above the glyph so the compact
  /// card's visible gap below the header matches `headerToHeroSpacing`.
  static let heroNumberLeadingTrim: CGFloat = -23
  /// Optical nudge so the hero text block centers against the display ring.
  static let heroTextRingOpticalOffset: CGFloat = SpaceToken.x1
  /// Gap between the hero number row and the quick-add footer.
  static let heroToFooterSpacing: CGFloat = SpaceToken.u2
  /// Quick-add button height — 8pt shorter than the standard button height.
  static let quickAddHeight: CGFloat = SizeToken.quickAddHeight - SpaceToken.u1
  /// Gap above the entry-added toast overlay.
  static let toastTopOffset: CGFloat = SpaceToken.u1

  /// Underlay list row ring — smaller than the full display ring so a single-line row stays short.
  static let listRingSize: CGFloat = 30
  /// Keeps the same 25% stroke-to-size ratio as `SizeToken.Ring.displayStroke` / `display`.
  static let listRingStroke: CGFloat = listRingSize * 0.25
}

/// Counters list underlay reveal — card peeks on the trailing edge when open.
enum RevealToken {
  /// Space between the counters list and the scaled counter card.
  static let listGap: CGFloat = GridToken.unit
  /// Visible horizontal width of the counter card when open (9 grid units).
  static let cardPeekWidth: CGFloat = GridToken.units(9)
  /// Extra card peek in compact mode — shrinks the underlay list by the same amount and
  /// reduces how far the main card has to slide to fully reveal it.
  static let compactExtraCardPeekWidth: CGFloat = 40
  /// Counter card scale when the list is fully open.
  static let openScale: CGFloat = 0.95

  static var maxScaleReduction: CGFloat {
    1 - openScale
  }

  static func cardPeekWidth(isCompact: Bool) -> CGFloat {
    cardPeekWidth + (isCompact ? compactExtraCardPeekWidth : 0)
  }

  static func listWidth(for screenWidth: CGFloat, isCompact: Bool = false) -> CGFloat {
    max(0, screenWidth - cardPeekWidth(isCompact: isCompact) - listGap - SpaceToken.scrollContainerInset)
  }

  static func cardContentWidth(forScreenWidth screenWidth: CGFloat) -> CGFloat {
    max(0, screenWidth - SpaceToken.scrollContainerInset * 2)
  }

  /// Horizontal offset for a fully open reveal (scale + slide right).
  static func openOffset(forCardWidth cardWidth: CGFloat, isCompact: Bool = false) -> CGFloat {
    max(0, openScale * cardWidth - cardPeekWidth(isCompact: isCompact))
  }

  /// Horizontal offset for a fully open reveal using the full screen width.
  static func openOffset(forScreenWidth screenWidth: CGFloat, isCompact: Bool = false) -> CGFloat {
    openOffset(
      forCardWidth: cardContentWidth(forScreenWidth: screenWidth),
      isCompact: isCompact
    )
  }

  /// Minimum drag distance before choosing horizontal reveal vs vertical scroll.
  static let axisDecisionDistance: CGFloat = GridToken.unit
}

enum HistoryToken {
  static let chartHeight: CGFloat = GridToken.units(28)
  static let chartPadding: CGFloat = SpaceToken.u2
  static let chartCornerRadius: CGFloat = RadiusToken.lg
  static let chartBarCornerRadius: CGFloat = RadiusToken.xs
  static let periodPickerHeight: CGFloat = GridToken.units(5)
  static let periodPickerInset: CGFloat = SpaceToken.x1
  static let sectionSpacing: CGFloat = SpaceToken.u3
  static let listRowHeight: CGFloat = 49
}

enum SheetToken {
  /// Gap between the top of the screen and modal sheets (5 grid units / 40pt).
  static let topOffset: CGFloat = GridToken.units(5)
  /// Entry log row height in modal sheet presentations (6 grid units / 48pt).
  static let tableRowHeight: CGFloat = GridToken.units(6)
  /// Horizontal inset for modal sheet content (2 grid units / 16pt).
  static let horizontal: CGFloat = SpaceToken.u2
  /// Top corner radius for modal sheet presentations (16pt).
  static let cornerRadius: CGFloat = RadiusToken.lg
  static let handleWidth: CGFloat = 36
  static let handleHeight: CGFloat = 5
  static let contentTop: CGFloat = SpaceToken.componentPadding
  static let headerSpacing: CGFloat = SpaceToken.u1
  static let headerIconSpacing: CGFloat = SpaceToken.u1
  static let amountTopSpacing: CGFloat = SpaceToken.u2
  static let actionTop: CGFloat = SpaceToken.u2
  static let amountInputHeight: CGFloat = FontSizeToken.x5xl
  static let keypadTopSpacing: CGFloat = SpaceToken.u2
  static let keypadKeySpacing: CGFloat = SpaceToken.u1
  static let keypadKeyHeight: CGFloat = GridToken.units(6)
  static let keypadKeyCornerRadius: CGFloat = RadiusToken.button
  static let keypadBottom: CGFloat = SpaceToken.u2
}
