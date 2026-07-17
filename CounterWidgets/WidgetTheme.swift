import SwiftUI

enum WidgetTheme {
  static let buttonHeight: CGFloat = 36
  static let buttonSpacing: CGFloat = 8
  static let buttonCornerRadius: CGFloat = 14
  static let buttonColumns = 4

  /// Ring size the design calls for — the app's own ring shrunk down to widget scale.
  static let ringSize: CGFloat = 48
  /// Scaled to the same proportion as the app's ring (`SizeToken.Ring.displayStroke` /
  /// `SizeToken.Ring.display` = 16 / 64 = 25%) so the stroke reads the same relative
  /// thickness at the smaller widget size.
  static let ringStroke: CGFloat = 12
  static let ringOverfillOutlineWidth: CGFloat = 2

  static let heroFontSize: CGFloat = 34
  static let subtitleFontSize: CGFloat = 18
  /// Matches `FontTrackingToken.tight2` in the app's type ramp.
  private static let trackingPercent: CGFloat = -2

  /// Small-widget-only sizes: the combined "value + title" headline used at medium width
  /// doesn't fit legibly in a small widget, so it splits back into its own title line above a
  /// dedicated hero number (18 / 40 / 14 semibold).
  static let smallTitleFontSize: CGFloat = 18
  static let smallValueFontSize: CGFloat = 40
  static let smallSubtitleFontSize: CGFloat = 14
  /// Gap between the progress ring and the title line — roughly one title-line of air.
  static let smallRingToTitleSpacing: CGFloat = 12
  /// Pulls the hero number up against the title (tight heading pair).
  static let smallTitleToValueSpacing: CGFloat = -4
  /// Slight air between the hero number and the remaining/to-go subtitle.
  static let smallValueToSubtitleSpacing: CGFloat = -2

  static func tracking(forSize size: CGFloat) -> CGFloat {
    size * (trackingPercent / 100)
  }

  static var heroFont: Font {
    .system(size: heroFontSize, weight: .semibold, design: .default)
  }

  static var heroTracking: CGFloat { tracking(forSize: heroFontSize) }

  static var subtitleFont: Font {
    .system(size: subtitleFontSize, weight: .semibold, design: .default)
  }

  static var subtitleTracking: CGFloat { tracking(forSize: subtitleFontSize) }

  static var smallTitleFont: Font {
    .system(size: smallTitleFontSize, weight: .semibold, design: .default)
  }

  static var smallTitleTracking: CGFloat { tracking(forSize: smallTitleFontSize) }

  static var smallValueFont: Font {
    .system(size: smallValueFontSize, weight: .semibold, design: .default)
  }

  static var smallValueTracking: CGFloat { tracking(forSize: smallValueFontSize) }

  static var smallSubtitleFont: Font {
    .system(size: smallSubtitleFontSize, weight: .semibold, design: .default)
  }

  static var smallSubtitleTracking: CGFloat { tracking(forSize: smallSubtitleFontSize) }
}

/// Home-screen counterpart to the app's `GoalProgressRing` (`Counter/Views/Components/GoalProgressRing.swift`).
/// Kept as a separate type rather than sharing that view directly since the widget extension can't
/// depend on the app-only `Counter/Design` module (semantic color environment, motion tokens, etc.) —
/// but it draws with the exact same `ProgressRingArc` geometry and fill/track/overflow-lap rules so the
/// two rings read identically, just at widget scale.
struct WidgetGoalProgressRing: View {
  let progress: GoalProgress
  let trackColor: Color
  let fillColor: Color
  let overfillOutlineColor: Color
  var size: CGFloat = WidgetTheme.ringSize
  var lineWidth: CGFloat = WidgetTheme.ringStroke

  private var fillFraction: Double {
    if progress.rendersEmptyRing { return 0 }
    if progress.isOverGoal { return 1 }
    return progress.ringFraction
  }

  var body: some View {
    ZStack {
      ProgressRingArc(fraction: 1, lineWidth: lineWidth)
        .stroke(trackColor, style: ringStrokeStyle)

      if fillFraction > 0 {
        ProgressRingArc(fraction: fillFraction, lineWidth: lineWidth)
          .stroke(fillColor, style: ringStrokeStyle)
      }

      if progress.overflowLoopProgress > 0 {
        loopOverlapArc(fraction: progress.overflowLoopProgress)
      }
    }
    .frame(width: size, height: size)
    .accessibilityLabel(progress.progressLabel)
    .accessibilityValue(progress.detailLabel)
  }

  private var ringStrokeStyle: StrokeStyle {
    StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
  }

  private func loopOverlapArc(fraction: Double) -> some View {
    let outlineWidth = WidgetTheme.ringOverfillOutlineWidth

    return ZStack {
      WidgetRingTipHalo(fraction: fraction, lineWidth: lineWidth, haloRadius: lineWidth / 2 + outlineWidth)
        .fill(overfillOutlineColor)

      ProgressRingArc(fraction: fraction, lineWidth: lineWidth)
        .stroke(fillColor, style: ringStrokeStyle)
    }
  }
}

/// Mirrors `GoalProgressRing`'s private `RingTipHalo` — see that type for the rationale on why
/// it's a small, self-contained shape duplicated per-target rather than shared.
private struct WidgetRingTipHalo: Shape {
  var fraction: Double
  var lineWidth: CGFloat
  var haloRadius: CGFloat

  func path(in rect: CGRect) -> Path {
    let clamped = Self.lapFraction(for: fraction)
    guard clamped > 0 else { return Path() }

    let insetRect = rect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
    let radius = min(insetRect.width, insetRect.height) / 2
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let sweepDegrees = clamped >= 0.999 ? 360 - 0.001 : clamped * 360
    let tipAngle = Angle.degrees(-90 + sweepDegrees)

    let tipPoint = CGPoint(
      x: center.x + radius * cos(tipAngle.radians),
      y: center.y + radius * sin(tipAngle.radians)
    )

    return Path(
      ellipseIn: CGRect(
        x: tipPoint.x - haloRadius,
        y: tipPoint.y - haloRadius,
        width: haloRadius * 2,
        height: haloRadius * 2
      )
    )
  }

  private static func lapFraction(for fraction: Double) -> Double {
    guard fraction > 0 else { return 0 }
    let wrapped = fraction.truncatingRemainder(dividingBy: 1)
    return wrapped == 0 ? 1 : wrapped
  }
}

struct WidgetQuickAddButton: View {
  let counter: CounterWidgetEntity
  let value: Int
  let colors: WidgetThemeColors

  var body: some View {
    Button(intent: AddCounterEntryIntent(counterID: counter.id, amount: value)) {
      Text("\(value)")
        .font(.system(size: 15, weight: .semibold, design: .rounded))
        .foregroundStyle(colors.buttonText)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
          colors.buttonFill,
          in: RoundedRectangle(cornerRadius: WidgetTheme.buttonCornerRadius, style: .continuous)
        )
    }
    .buttonStyle(.plain)
  }
}
