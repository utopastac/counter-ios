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
  static let u5: CGFloat = GridToken.units(5)
  static let u6: CGFloat = GridToken.units(6)
  static let u7: CGFloat = GridToken.units(7)
  static let u8: CGFloat = GridToken.units(8)

  /// Page horizontal inset and default component padding (1 grid unit).
  static let pageMargin: CGFloat = u1
  static let componentPadding: CGFloat = u1

  static let pageHorizontal: CGFloat = pageMargin
  static let toolbarHorizontal: CGFloat = pageMargin

  static let pageTopInset: CGFloat = toolbarTop + SizeToken.iconButton + toolbarBottom + BorderToken.toolbar
  static let pageFooterBottom: CGFloat = u7
  static let toolbarTop: CGFloat = u1
  static let toolbarBottom: CGFloat = u1

  /// Inset around the vertical counter pager card from the screen edge.
  static let scrollContainerInset: CGFloat = u1

  // Legacy aliases — map to grid multiples where possible.
  static let x1: CGFloat = u1 / 2
  static let x2: CGFloat = u1
  static let x3: CGFloat = u1 + x1
  static let x4: CGFloat = u2
  static let x5: CGFloat = u2 + x1
  static let x6: CGFloat = u3
  static let x7: CGFloat = u3 + x1
}

enum RadiusToken {
  static let xs: CGFloat = GridToken.units(1)
  static let sm: CGFloat = GridToken.unit * 1.5
  static let md: CGFloat = 14
  static let lg: CGFloat = 16
  static let xl: CGFloat = 18
  static let xxl: CGFloat = 28

  /// Counter list cards and matching list actions (12pt).
  static let listCard: CGFloat = sm

  /// Vertical counter pager card — fixed 16pt (2 grid units) corners.
  static let scrollContainer: CGFloat = SpaceToken.u2

  /// Pager card when counters list is revealed.
  static let revealCard: CGFloat = scrollContainer

  /// Legacy alias for reveal card radius.
  static let card: CGFloat = revealCard

  static var continuousXs: RoundedRectangle {
    RoundedRectangle(cornerRadius: xs, style: .continuous)
  }

  static var continuousSm: RoundedRectangle {
    RoundedRectangle(cornerRadius: sm, style: .continuous)
  }

  static var continuousMd: RoundedRectangle {
    RoundedRectangle(cornerRadius: md, style: .continuous)
  }

  static var continuousLg: RoundedRectangle {
    RoundedRectangle(cornerRadius: lg, style: .continuous)
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
}

enum EntryLogPreviewLimit {
  static let count = 5
}

enum SizeToken {
  static let iconButton: CGFloat = 24
  static let iconGlyph: CGFloat = 20
  static let iconStroke: CGFloat = 2
  static let quickAddHeight: CGFloat = 44
  static let primaryButtonHeight: CGFloat = 56
  static let gridColumnCount: Int = 5
  static let gridSpacing: CGFloat = SpaceToken.x2

  enum Ring {
    static let display: CGFloat = GridToken.units(8)
    static let displayStroke: CGFloat = 16
    static let list: CGFloat = display
    static let listStroke: CGFloat = displayStroke
    static let hero: CGFloat = display
    static let heroStroke: CGFloat = displayStroke
    static let `default`: CGFloat = display
    static let defaultStroke: CGFloat = displayStroke
    static let progressStroke: CGFloat = displayStroke
    static let overfillOutlineWidth: CGFloat = 2
  }
}

enum ShadowToken {
  static let subtleRadius: CGFloat = 12
  static let subtleY: CGFloat = 4

  static func subtle(_ colors: SemanticColors = .dark) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
    (BaseColor.BlackAlpha.a120, subtleRadius, 0, subtleY)
  }

  static func reveal(progress: CGFloat) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
    (
      BaseColor.BlackAlpha.a280.opacity(progress),
      28 * progress,
      -12 * progress,
      6 * progress
    )
  }
}

enum MotionToken {
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
}

/// Counters list underlay reveal — card peeks on the trailing edge when open.
enum RevealToken {
  /// Space between the counters list and the scaled counter card.
  static let listGap: CGFloat = GridToken.unit
  /// Visible horizontal width of the counter card when open (9 grid units).
  static let cardPeekWidth: CGFloat = GridToken.units(9)
  /// Counter card scale when the list is fully open.
  static let openScale: CGFloat = 0.95

  static var maxScaleReduction: CGFloat {
    1 - openScale
  }

  static func listWidth(for screenWidth: CGFloat) -> CGFloat {
    max(0, screenWidth - cardPeekWidth - listGap)
  }

  static func cardContentWidth(forScreenWidth screenWidth: CGFloat) -> CGFloat {
    max(0, screenWidth - SpaceToken.scrollContainerInset * 2)
  }

  /// Horizontal offset for a fully open reveal (scale + slide right).
  static func openOffset(forCardWidth cardWidth: CGFloat) -> CGFloat {
    max(0, openScale * cardWidth - cardPeekWidth)
  }

  /// Horizontal offset for a fully open reveal using the full screen width.
  static func openOffset(forScreenWidth screenWidth: CGFloat) -> CGFloat {
    openOffset(forCardWidth: cardContentWidth(forScreenWidth: screenWidth))
  }
}

enum SheetToken {
  static let horizontal: CGFloat = SpaceToken.pageMargin
  static let handleWidth: CGFloat = 36
  static let handleHeight: CGFloat = 5
  static let contentTop: CGFloat = SpaceToken.componentPadding
  static let headerSpacing: CGFloat = SpaceToken.u1
  static let headerIconSpacing: CGFloat = SpaceToken.u1
  static let amountTopSpacing: CGFloat = SpaceToken.u2
  static let actionTop: CGFloat = SpaceToken.u2
  static let contentBottom: CGFloat = SpaceToken.u3
  static let amountInputHeight: CGFloat = FontSizeToken.x5xl
  static let keypadTopSpacing: CGFloat = SpaceToken.x4
  static let keypadKeySpacing: CGFloat = SpaceToken.x2
  static let keypadKeyHeight: CGFloat = 56
  static let keypadBottom: CGFloat = SpaceToken.x2
}
