import SwiftUI

struct GoalProgressRing: View {
  @Environment(\.semanticColors) private var colors
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @AppStorage(
    AppAppearancePreference.progressRingWidthKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var ringWidthRaw = ProgressRingWidth.balanced.rawValue
  @AppStorage(
    AppAppearancePreference.progressRingGlowEnabledKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var ringGlowEnabled = false

  let progress: GoalProgress
  var size: CGFloat = SizeToken.Ring.default
  /// Optional override; when `nil`, uses the counter override or global ring-width preference.
  var lineWidth: CGFloat? = nil
  /// Per-counter width override; `nil` falls back to the app setting (ignored when `lineWidth` is set).
  var ringWidthOverride: ProgressRingWidth? = nil
  /// Per-counter glow override; `nil` falls back to the app setting.
  var ringGlowOverride: Bool? = nil
  var trackColor: Color?
  var fillColor: Color?

  private var resolvedRingWidth: ProgressRingWidth {
    ringWidthOverride ?? ProgressRingWidth(rawValue: ringWidthRaw) ?? .balanced
  }

  private var resolvedRingGlow: Bool {
    ringGlowOverride ?? ringGlowEnabled
  }

  private var resolvedLineWidth: CGFloat {
    if let lineWidth { return lineWidth }
    return resolvedRingWidth.strokeWidth(for: size)
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
      ringLayer(fraction: 1, color: resolvedTrackColor)
        .blur(radius: resolvedRingGlow ? ProgressRingGlowMetrics.trackBlurRadius : 0)

      if resolvedRingGlow {
        ringTrackGlow()
      }

      if fillFraction > 0 {
        ringLayer(fraction: fillFraction, color: resolvedFillColor)
      }

      if progress.overflowLoopProgress > 0 {
        ringLayer(fraction: progress.overflowLoopProgress, color: resolvedFillColor)
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

  private func ringShape(fraction: Double) -> ProgressRingArc {
    ProgressRingArc(fraction: fraction, lineWidth: resolvedLineWidth)
  }

  private func ringLayer(fraction: Double, color: Color) -> some View {
    ringShape(fraction: fraction)
      .stroke(color, style: ringStrokeStyle)
  }

  /// Soft highlight on the *track* (background) ring, clipped to the track band.
  private func ringTrackGlow() -> some View {
    ringLayer(fraction: 1, color: Color.white.opacity(ProgressRingGlowMetrics.highlightOpacity))
      .blur(radius: resolvedLineWidth * ProgressRingGlowMetrics.highlightBlurFactor)
      .mask {
        ringLayer(fraction: 1, color: .white)
      }
      .blendMode(.plusLighter)
      .allowsHitTesting(false)
  }

  /// Bordered tip cap stacked above the ring. Outline is only the *front* half (leading side in
  /// the direction of travel) so the rim never paints under the lap behind the tip.
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

      RingTipHalo(
        fraction: fraction,
        lineWidth: resolvedLineWidth,
        haloRadius: tipRadius
      )
      .fill(resolvedFillColor)
    }
    .mask {
      ringLayer(fraction: 1, color: .white)
    }
  }

  private var resolvedTrackColor: Color {
    trackColor ?? colors.progressRingTrack
  }

  private var resolvedFillColor: Color {
    fillColor ?? colors.progressRingFill
  }
}

/// A filled disc (or leading half) centered on the tip of a `ProgressRingArc`. Used for the
/// progress tip's outline rim and matching fill cap — always drawn only at the growing end.
private struct RingTipHalo: Shape {
  var fraction: Double
  var lineWidth: CGFloat
  var haloRadius: CGFloat
  /// When true, draws only the leading half (bulging in the direction of travel) so the
  /// outline rim sits on the front of the tip and not on the half that overlaps earlier ring.
  var frontHalfOnly = false

  var animatableData: Double {
    get { fraction }
    set { fraction = newValue }
  }

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
