import SwiftUI

/// Layout tokens — spacing, radius, size, shadow.
enum SpaceToken {
  static let x1: CGFloat = 4
  static let x2: CGFloat = 8
  static let x3: CGFloat = 12
  static let x4: CGFloat = 16
  static let x5: CGFloat = 20
  static let x6: CGFloat = 24
  static let x7: CGFloat = 28

  static let pageHorizontal: CGFloat = 24
  static let pageTopInset: CGFloat = 64
  static let pageFooterBottom: CGFloat = 56
  static let toolbarHorizontal: CGFloat = 20
  static let toolbarTop: CGFloat = 12
}

enum RadiusToken {
  static let sm: CGFloat = 12
  static let md: CGFloat = 14
  static let lg: CGFloat = 16
  static let xl: CGFloat = 18
  static let card: CGFloat = 28

  static var continuousSm: RoundedRectangle {
    RoundedRectangle(cornerRadius: sm, style: .continuous)
  }

  static var continuousMd: RoundedRectangle {
    RoundedRectangle(cornerRadius: md, style: .continuous)
  }

  static var continuousLg: RoundedRectangle {
    RoundedRectangle(cornerRadius: lg, style: .continuous)
  }

  static func continuous(_ radius: CGFloat) -> RoundedRectangle {
    RoundedRectangle(cornerRadius: radius, style: .continuous)
  }
}

enum SizeToken {
  static let iconButton: CGFloat = 40
  static let quickAddHeight: CGFloat = 44
  static let primaryButtonHeight: CGFloat = 56
  static let gridColumnCount: Int = 4
  static let gridSpacing: CGFloat = SpaceToken.x2

  enum Ring {
    static let list: CGFloat = 52
    static let listStroke: CGFloat = 10
    static let hero: CGFloat = 76
    static let heroStroke: CGFloat = 16
    static let `default`: CGFloat = 88
    static let defaultStroke: CGFloat = 16
    static let progressStroke: CGFloat = 16
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

enum SheetToken {
  static let horizontal: CGFloat = SpaceToken.x5
  static let handleWidth: CGFloat = 36
  static let handleHeight: CGFloat = 5
  static let contentTop: CGFloat = SpaceToken.x4
  static let headerSpacing: CGFloat = SpaceToken.x2
  static let amountTopSpacing: CGFloat = SpaceToken.x4
  static let actionTop: CGFloat = SpaceToken.x5
  static let contentBottom: CGFloat = SpaceToken.x6
  static let amountInputHeight: CGFloat = 72
  static let keypadTopSpacing: CGFloat = SpaceToken.x4
  static let keypadKeySpacing: CGFloat = SpaceToken.x2
  static let keypadKeyHeight: CGFloat = 56
  static let keypadBottom: CGFloat = SpaceToken.x2
}
