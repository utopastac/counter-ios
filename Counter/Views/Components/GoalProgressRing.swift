import SwiftUI

struct GoalProgressRing: View {
  @Environment(\.semanticColors) private var colors
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @AppStorage(
    AppAppearancePreference.progressRingWidthKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var ringWidthRaw = ProgressRingWidth.balanced.rawValue
  @AppStorage(
    AppAppearancePreference.progressRingStyleKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var ringStyleRaw = ProgressRingStyle.solid.rawValue
  @AppStorage(
    AppAppearancePreference.progressRingGlowEnabledKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var ringGlowEnabled = false

  let progress: GoalProgress
  var size: CGFloat = SizeToken.Ring.default
  /// Optional override; when `nil`, uses the counter override or global ring-width preference.
  var lineWidth: CGFloat? = nil
  /// Per-counter style override; `nil` falls back to the app setting via `@AppStorage`.
  var ringStyleOverride: ProgressRingStyle? = nil
  /// Per-counter width override; `nil` falls back to the app setting (ignored when `lineWidth` is set).
  var ringWidthOverride: ProgressRingWidth? = nil
  /// Per-counter glow override; `nil` falls back to the app setting.
  var ringGlowOverride: Bool? = nil
  var trackColor: Color?
  var fillColor: Color?

  private var resolvedRingWidth: ProgressRingWidth {
    ringWidthOverride ?? ProgressRingWidth(rawValue: ringWidthRaw) ?? .balanced
  }

  private var resolvedRingStyle: ProgressRingStyle {
    ringStyleOverride ?? ProgressRingStyle(rawValue: ringStyleRaw) ?? .solid
  }

  private var resolvedRingGlow: Bool {
    ringGlowOverride ?? ringGlowEnabled
  }

  private var ringSides: Int? {
    resolvedRingStyle.ringSides
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
      if resolvedRingStyle.showsTip, tipFraction > 0 {
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
    resolvedRingStyle.strokeStyle(lineWidth: resolvedLineWidth)
  }

  private func ringShape(fraction: Double) -> ProgressRingArc {
    ProgressRingArc(fraction: fraction, lineWidth: resolvedLineWidth, sides: ringSides)
  }

  @ViewBuilder
  private func ringLayer(fraction: Double, color: Color) -> some View {
    let shape = ringShape(fraction: fraction)
    if shape.usesFill {
      shape.fill(color)
    } else {
      shape.stroke(color, style: ringStrokeStyle)
    }
  }

  /// Soft inner glow on the *track* (background) ring, clipped to the track band.
  private func ringTrackGlow() -> some View {
    ringLayer(fraction: 1, color: Color.white.opacity(0.55))
      .blur(radius: resolvedLineWidth * 0.35)
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
    let flat = resolvedRingStyle.usesFlatTip
    // Polygon tips are a thin end-cap — just deep enough for the outline rim to read.
    let fillExtent = flat ? outlineWidth : tipRadius
    let outlineExtent = flat ? outlineWidth : tipRadius + outlineWidth

    return ZStack {
      RingTipHalo(
        fraction: fraction,
        lineWidth: resolvedLineWidth,
        haloRadius: outlineExtent,
        sides: ringSides,
        frontHalfOnly: true,
        flat: flat
      )
      .fill(colors.progressRingOverfillOutline)

      RingTipHalo(
        fraction: fraction,
        lineWidth: resolvedLineWidth,
        haloRadius: fillExtent,
        sides: ringSides,
        flat: flat
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

/// A filled disc/rect (or leading half) centered on the tip of a `ProgressRingArc`. Used for the
/// progress tip's outline rim and matching fill cap — always drawn only at the growing end.
private struct RingTipHalo: Shape {
  var fraction: Double
  var lineWidth: CGFloat
  var haloRadius: CGFloat
  var sides: Int? = nil
  /// When true, draws only the leading half (bulging in the direction of travel) so the
  /// outline rim sits on the front of the tip and not on the half that overlaps earlier ring.
  var frontHalfOnly = false
  /// Polygon rings — flat rectangular tip instead of a round disc.
  var flat = false

  var animatableData: Double {
    get { fraction }
    set { fraction = newValue }
  }

  func path(in rect: CGRect) -> Path {
    guard let pose = ProgressRingGeometry.tipPose(
      fraction: fraction,
      in: rect,
      lineWidth: lineWidth,
      sides: sides
    ) else { return Path() }

    let tipPoint = pose.point
    let travelRadians = pose.travelRadians
    // Across-stroke axis (perpendicular to travel).
    let radial = CGPoint(x: cos(travelRadians - .pi / 2), y: sin(travelRadians - .pi / 2))
    let travel = CGPoint(x: cos(travelRadians), y: sin(travelRadians))

    if flat {
      // `haloRadius` is travel depth only; across-stroke width matches the ring (plus rim
      // overhang on the outline layer). Fill sits behind the tip face; outline is the front rim.
      let halfWidth = lineWidth / 2 + (frontHalfOnly ? haloRadius : 0)
      let travelStart: CGFloat = frontHalfOnly ? 0 : -haloRadius
      let travelEnd: CGFloat = frontHalfOnly ? haloRadius : 0
      return Self.rectPath(
        center: tipPoint,
        radial: radial,
        travel: travel,
        halfWidth: halfWidth,
        travelStart: travelStart,
        travelEnd: travelEnd
      )
    }

    // Round tip: radial angle is travel − 90° (outward from ring center on a circle).
    let tipAngle = Angle.radians(travelRadians - .pi / 2)

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

  private static func rectPath(
    center: CGPoint,
    radial: CGPoint,
    travel: CGPoint,
    halfWidth: CGFloat,
    travelStart: CGFloat,
    travelEnd: CGFloat
  ) -> Path {
    let corners = [
      CGPoint(
        x: center.x + radial.x * (-halfWidth) + travel.x * travelStart,
        y: center.y + radial.y * (-halfWidth) + travel.y * travelStart
      ),
      CGPoint(
        x: center.x + radial.x * halfWidth + travel.x * travelStart,
        y: center.y + radial.y * halfWidth + travel.y * travelStart
      ),
      CGPoint(
        x: center.x + radial.x * halfWidth + travel.x * travelEnd,
        y: center.y + radial.y * halfWidth + travel.y * travelEnd
      ),
      CGPoint(
        x: center.x + radial.x * (-halfWidth) + travel.x * travelEnd,
        y: center.y + radial.y * (-halfWidth) + travel.y * travelEnd
      ),
    ]
    var path = Path()
    path.move(to: corners[0])
    path.addLine(to: corners[1])
    path.addLine(to: corners[2])
    path.addLine(to: corners[3])
    path.closeSubpath()
    return path
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
