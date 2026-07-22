import SwiftUI

enum WidgetTheme {
  static let buttonHeight: CGFloat = 36
  static let buttonSpacing: CGFloat = 8
  static let buttonCornerRadius: CGFloat = 14
  static let buttonColumns = 4

  /// Ring size the design calls for — the app's own ring shrunk down to widget scale.
  static let ringSize: CGFloat = 48
  /// Larger ring for the home-screen large widget.
  static let largeRingSize: CGFloat = 72
  /// Compact ring for lock-screen circular widgets.
  static let accessoryRingSize: CGFloat = 36
  /// Stroke follows the shared `ProgressRingWidth` preference (balanced = 25% of size).
  static var ringStroke: CGFloat {
    AppAppearancePreference.progressRingWidth.strokeWidth(for: ringSize)
  }
  static let ringOverfillOutlineWidth: CGFloat = 2

  static let heroFontSize: CGFloat = 34
  static let subtitleFontSize: CGFloat = 18
  static let largeHeroFontSize: CGFloat = 48
  static let largeSubtitleFontSize: CGFloat = 20
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

  static func packFont(size: CGFloat, weight: Font.Weight = .semibold) -> Font {
    AppAppearancePreference.fontPack.font(size: size, weight: weight)
  }

  static var heroFont: Font {
    packFont(size: heroFontSize)
  }

  static var heroTracking: CGFloat { tracking(forSize: heroFontSize) }

  static var subtitleFont: Font {
    packFont(size: subtitleFontSize)
  }

  static var subtitleTracking: CGFloat { tracking(forSize: subtitleFontSize) }

  static var largeHeroFont: Font {
    packFont(size: largeHeroFontSize)
  }

  static var largeHeroTracking: CGFloat { tracking(forSize: largeHeroFontSize) }

  static var largeSubtitleFont: Font {
    packFont(size: largeSubtitleFontSize)
  }

  static var largeSubtitleTracking: CGFloat { tracking(forSize: largeSubtitleFontSize) }

  static var smallTitleFont: Font {
    packFont(size: smallTitleFontSize)
  }

  static var smallTitleTracking: CGFloat { tracking(forSize: smallTitleFontSize) }

  static var smallValueFont: Font {
    packFont(size: smallValueFontSize)
  }

  static var smallValueTracking: CGFloat { tracking(forSize: smallValueFontSize) }

  static var smallSubtitleFont: Font {
    packFont(size: smallSubtitleFontSize)
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
  var lineWidth: CGFloat? = nil
  var ringWidthOverride: ProgressRingWidth? = nil
  var ringGlowOverride: Bool? = nil

  private var resolvedLineWidth: CGFloat {
    if let lineWidth { return lineWidth }
    let width = ringWidthOverride ?? AppAppearancePreference.progressRingWidth
    return width.strokeWidth(for: size)
  }

  private var ringGlowEnabled: Bool {
    ringGlowOverride ?? AppAppearancePreference.isProgressRingGlowEnabled
  }

  private var fillFraction: Double {
    if progress.rendersEmptyRing { return 0 }
    if progress.isOverGoal { return 1 }
    return progress.ringFraction
  }

  var body: some View {
    ZStack {
      ringLayer(fraction: 1, color: trackColor)
        .blur(radius: ringGlowEnabled ? ProgressRingGlowMetrics.trackBlurRadius : 0)

      if ringGlowEnabled {
        ringLayer(fraction: 1, color: Color.white.opacity(ProgressRingGlowMetrics.highlightOpacity))
          .blur(radius: resolvedLineWidth * ProgressRingGlowMetrics.highlightBlurFactor)
          .mask { ringLayer(fraction: 1, color: .white) }
          .blendMode(.plusLighter)
      }

      if fillFraction > 0 {
        ringLayer(fraction: fillFraction, color: fillColor)
      }

      if progress.overflowLoopProgress > 0 {
        ringLayer(fraction: progress.overflowLoopProgress, color: fillColor)
      }

      if tipFraction > 0 {
        ringTip(at: tipFraction)
      }
    }
    .frame(width: size, height: size)
    .accessibilityLabel(progress.progressLabel)
    .accessibilityValue(progress.detailLabel)
  }

  private var tipFraction: Double {
    if progress.overflowLoopProgress > 0 {
      progress.overflowLoopProgress
    } else {
      fillFraction
    }
  }

  private var ringStrokeStyle: StrokeStyle {
    StrokeStyle(lineWidth: resolvedLineWidth, lineCap: .round, lineJoin: .round)
  }

  private func ringLayer(fraction: Double, color: Color) -> some View {
    ProgressRingArc(fraction: fraction, lineWidth: resolvedLineWidth)
      .stroke(color, style: ringStrokeStyle)
  }

  /// Mirrors `GoalProgressRing.ringTip(at:)`.
  private func ringTip(at fraction: Double) -> some View {
    let tipRadius = resolvedLineWidth / 2
    let outlineWidth = WidgetTheme.ringOverfillOutlineWidth

    return ZStack {
      WidgetRingTipHalo(
        fraction: fraction,
        lineWidth: resolvedLineWidth,
        haloRadius: tipRadius + outlineWidth,
        frontHalfOnly: true
      )
      .fill(overfillOutlineColor)

      WidgetRingTipHalo(
        fraction: fraction,
        lineWidth: resolvedLineWidth,
        haloRadius: tipRadius
      )
      .fill(fillColor)
    }
    .mask {
      ringLayer(fraction: 1, color: .white)
    }
  }
}

/// Mirrors `GoalProgressRing`'s private `RingTipHalo` — see that type for the rationale on why
/// it's a small, self-contained shape duplicated per-target rather than shared.
private struct WidgetRingTipHalo: Shape {
  var fraction: Double
  var lineWidth: CGFloat
  var haloRadius: CGFloat
  var frontHalfOnly = false

  func path(in rect: CGRect) -> Path {
    guard let pose = ProgressRingGeometry.tipPose(
      fraction: fraction,
      in: rect,
      lineWidth: lineWidth
    ) else { return Path() }

    let tipPoint = pose.point
    let tipAngle = Angle.radians(pose.travelRadians - .pi / 2)

    if frontHalfOnly {
      var path = Path()
      path.addArc(
        center: tipPoint,
        radius: haloRadius,
        startAngle: tipAngle,
        endAngle: tipAngle + .degrees(180),
        clockwise: false
      )
      path.closeSubpath()
      return path
    }

    return Path(
      ellipseIn: CGRect(
        x: tipPoint.x - haloRadius,
        y: tipPoint.y - haloRadius,
        width: haloRadius * 2,
        height: haloRadius * 2
      )
    )
  }
}

struct WidgetQuickAddButton: View {
  let counter: CounterWidgetEntity
  let value: Double
  let colors: WidgetThemeColors

  var body: some View {
    Button(intent: AddCounterEntryIntent(counterID: counter.id, amount: value)) {
      Text(CounterFormatting.amount(value))
        .font(WidgetTheme.packFont(size: 15))
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
