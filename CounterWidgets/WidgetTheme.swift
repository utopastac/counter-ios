import SwiftUI

enum WidgetTheme {
  static let buttonHeight: CGFloat = 36
  static let buttonSpacing: CGFloat = 8
  static let buttonCornerRadius: CGFloat = 14
  static let buttonColumns = 4
  /// Matches the app's `EntryLogToken.rowHeight` (40pt) for large-widget entry rows.
  static let entryRowHeight: CGFloat = 40
  /// Gap between the hero header and the quick-add grid (medium + large).
  static let headerToQuickAddSpacing: CGFloat = 12
  /// Air between the quick-add grid and the recent-entry list on the large widget.
  static let largeQuickAddToEntriesSpacing: CGFloat = 12
  /// Shared content inset for medium + large so both headers lay out identically.
  static let homeScreenContentMargin: CGFloat = 16

  /// Ring size the design calls for — the app's own ring shrunk down to widget scale.
  static let ringSize: CGFloat = 48
  /// Compact ring for lock-screen circular widgets.
  static let accessoryRingSize: CGFloat = 36
  /// Stroke follows the shared `ProgressRingWidth` preference (balanced = 25% of size).
  static var ringStroke: CGFloat {
    AppAppearancePreference.progressRingWidth.strokeWidth(for: ringSize)
  }
  static let ringOverfillOutlineWidth: CGFloat = 2

  /// Fixed hero size for medium + large — matched to the home-screen reference screenshot.
  static let heroFontSize: CGFloat = 23
  /// Fixed subtitle under the hero on medium + large.
  static let subtitleFontSize: CGFloat = 16
  /// Pulls the subtitle up under the hero (tight stacked pair from the reference).
  static let heroToSubtitleSpacing: CGFloat = 0
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

  static func tracking(forSize size: CGFloat, percent: CGFloat) -> CGFloat {
    size * (percent / 100)
  }

  static func packFont(size: CGFloat, weight: Font.Weight = .semibold) -> Font {
    AppAppearancePreference.fontPack.font(size: size, weight: weight)
  }

  static var heroFont: Font {
    packFont(size: heroFontSize, weight: .semibold)
  }

  static var heroTracking: CGFloat { tracking(forSize: heroFontSize) }

  static var subtitleFont: Font {
    packFont(size: subtitleFontSize, weight: .semibold)
  }

  static var subtitleTracking: CGFloat { tracking(forSize: subtitleFontSize) }

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

/// Newest-first entry rows for the large widget — mirrors `CompactEntryLogPreview` /
/// `EntryLogRow` (value, timestamp, delete) without pulling app-only design tokens into
/// the extension.
struct WidgetRecentEntriesList: View {
  let entries: [CounterWidgetRecentEntry]
  let colors: WidgetThemeColors

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Matches `EntryLogPreviewTableDivider` / `SettingsDivider`.
      Rectangle()
        .fill(colors.foreground.opacity(0.40))
        .frame(height: 1)

      ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
        if index > 0 {
          // Matches `EntryLogRowDivider`.
          Rectangle()
            .fill(colors.foreground.opacity(0.40))
            .frame(height: 1)
        }

        WidgetRecentEntryRow(entry: entry, colors: colors)
          .frame(height: WidgetTheme.entryRowHeight)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }
}

private struct WidgetRecentEntryRow: View {
  let entry: CounterWidgetRecentEntry
  let colors: WidgetThemeColors

  /// Same format as `EntryLogRow.timestampFormat`.
  private static let timestampFormat = Date.FormatStyle()
    .month(.abbreviated)
    .day(.twoDigits)
    .hour(.defaultDigits(amPM: .abbreviated))
    .minute(.twoDigits)

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      // `CounterTextStyle.entryLogValue` → `TypeStyle.lgSemibold` (18 / semibold / -3%).
      Text(entry.valueText)
        .font(WidgetTheme.packFont(size: 18, weight: .semibold))
        .tracking(WidgetTheme.tracking(forSize: 18, percent: -3))
        .foregroundStyle(colors.foreground)
        .lineLimit(1)
        .minimumScaleFactor(0.8)

      Spacer(minLength: 0)

      // `CounterTextStyle.entryLogTimestamp` → `TypeStyle.mdRegular` (16 / regular / -2%).
      Text(entry.timestamp, format: Self.timestampFormat)
        .font(WidgetTheme.packFont(size: 16, weight: .regular))
        .tracking(WidgetTheme.tracking(forSize: 16, percent: -2))
        .foregroundStyle(colors.foreground)
        .lineLimit(1)

      Button(intent: DeleteCounterEntryIntent(entryID: entry.id)) {
        Image(systemName: "xmark")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(colors.foreground)
          .frame(width: 20, height: 20)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Delete entry")
    }
  }
}
