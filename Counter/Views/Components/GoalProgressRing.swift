import SwiftUI

struct GoalProgressRing: View {
  @Environment(\.semanticColors) private var colors
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @AppStorage(
    AppAppearancePreference.progressRingWidthKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var ringWidthRaw = ProgressRingWidth.balanced.rawValue

  let progress: GoalProgress
  var size: CGFloat = SizeToken.Ring.default
  /// Optional override; when `nil`, uses the global ring-width preference.
  var lineWidth: CGFloat? = nil
  var trackColor: Color?
  var fillColor: Color?

  private var resolvedLineWidth: CGFloat {
    if let lineWidth { return lineWidth }
    let width = ProgressRingWidth(rawValue: ringWidthRaw) ?? .balanced
    return width.strokeWidth(for: size)
  }

  /// The primary 0...1 lap. Snaps to the full ring once a count-up target is exceeded (the
  /// overflow arc then wraps on top of it) and drops to empty for anything else out of
  /// range — negative progress in either direction, or a count-down budget gone over.
  private var fillFraction: Double {
    if progress.rendersEmptyRing { return 0 }
    if progress.isOverGoal { return 1 }
    return progress.ringFraction
  }

  var body: some View {
    ZStack {
      ProgressRingArc(fraction: 1, lineWidth: resolvedLineWidth)
        .stroke(resolvedTrackColor, style: ringStrokeStyle)

      if fillFraction > 0 {
        ProgressRingArc(fraction: fillFraction, lineWidth: resolvedLineWidth)
          .stroke(resolvedFillColor, style: ringStrokeStyle)
      }

      if progress.overflowLoopProgress > 0 {
        ProgressRingArc(fraction: progress.overflowLoopProgress, lineWidth: resolvedLineWidth)
          .stroke(resolvedFillColor, style: ringStrokeStyle)
      }

      // Tip rim always sits above stroke geometry so it stays visible on and past target.
      if tipFraction > 0 {
        ringTip(at: tipFraction)
      }
    }
    .animation(MotionToken.ringProgress(reduceMotion: reduceMotion), value: progress.current)
    .frame(width: size, height: size)
    .accessibilityLabel(progress.progressLabel)
    .accessibilityValue(progress.detailLabel)
  }

  /// Tip follows the overflow lap when wrapping; otherwise the primary fill.
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

  /// Bordered tip cap stacked above the ring. Outline is only the *front* semicircle (leading
  /// half in the direction of travel) so the rim never paints under the lap behind the tip.
  ///
  /// `fraction` may be the continuous, unwrapped `overflowLoopProgress` (can be > 1) — the tip
  /// shape wraps it into `(0, 1]` when drawing so animation stays monotonic across lap boundaries.
  private func ringTip(at fraction: Double) -> some View {
    let tipRadius = resolvedLineWidth / 2
    let outlineWidth = SizeToken.Ring.overfillOutlineWidth

    return ZStack {
      RingTipHalo(
        fraction: fraction,
        lineWidth: resolvedLineWidth,
        haloRadius: tipRadius + outlineWidth,
        frontHalfOnly: true
      )
      .fill(colors.progressRingOverfillOutline)

      RingTipHalo(fraction: fraction, lineWidth: resolvedLineWidth, haloRadius: tipRadius)
        .fill(resolvedFillColor)
    }
  }

  private var resolvedTrackColor: Color {
    trackColor ?? colors.progressRingTrack
  }

  private var resolvedFillColor: Color {
    fillColor ?? colors.progressRingFill
  }
}

/// A filled disc (or leading semicircle) centered on the tip of a `ProgressRingArc` with the
/// same `fraction`/`lineWidth`. Used for the progress tip's outline rim and matching fill cap —
/// always drawn only at the growing end, never at the fixed 12 o'clock start.
private struct RingTipHalo: Shape {
  var fraction: Double
  var lineWidth: CGFloat
  var haloRadius: CGFloat
  /// When true, draws only the leading semicircle (bulging in the direction of travel) so the
  /// outline rim sits on the front of the tip and not on the half that overlaps earlier ring.
  var frontHalfOnly = false

  var animatableData: Double {
    get { fraction }
    set { fraction = newValue }
  }

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

    if frontHalfOnly {
      // Diameter along the radial axis; arc sweeps CCW through the clockwise-travel direction.
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

  /// See `ProgressRingArc`'s identical helper — kept local rather than shared since this is a
  /// tiny, self-contained shape and pulling in a cross-file dependency isn't worth it.
  private static func lapFraction(for fraction: Double) -> Double {
    guard fraction > 0 else { return 0 }
    let wrapped = fraction.truncatingRemainder(dividingBy: 1)
    return wrapped == 0 ? 1 : wrapped
  }
}

#Preview {
  ZStack {
    CounterPagerBackdrop(accents: [.calories], scrollProgress: 0)
    VStack(spacing: SpaceToken.x4) {
      GoalProgressRing(
        progress: GoalProgress(current: 500, goal: 2000, direction: .countDown)
      )
      GoalProgressRing(
        progress: GoalProgress(current: 1800, goal: 2000, direction: .countDown)
      )
      GoalProgressRing(
        progress: GoalProgress(current: 2150, goal: 2000, direction: .countDown)
      )
      GoalProgressRing(
        progress: GoalProgress(current: 3200, goal: 2000, direction: .countDown)
      )
      GoalProgressRing(
        progress: GoalProgress(current: 6800, goal: 2000, direction: .countUp)
      )
      GoalProgressRing(
        progress: GoalProgress(current: -900, goal: 2000, direction: .countUp)
      )
    }
    .padding()
  }
  .counterDesignSystem(CounterDesignSystem(colorScheme: .light, accent: .calories))
  .preferredColorScheme(.light)
}
