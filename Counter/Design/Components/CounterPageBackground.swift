import Observation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Holds live pager scroll chrome. Kept in a dedicated `@Observable` object so that
/// per-frame scroll updates and drag-phase flips only invalidate the small views that
/// read these properties — not `CounterPagerView`, which would otherwise rebuild the
/// paging `ScrollView` and re-apply `scrollPosition` (a visible up/down jump on the last
/// page, where the resting offset often sits slightly off the ideal page boundary).
@Observable
final class PagerScrollState {
  var value: CGFloat = 0
  var isDragging = false
}

/// Leaf wrapper that reads the observable scroll progress and feeds it into the value-based
/// `CounterPagerBackdrop`. The observable read is isolated here so only this view re-renders
/// while the pager is being swiped.
struct PagerBackdropView: View {
  let accents: [CounterAccent]
  let scrollState: PagerScrollState

  var body: some View {
    CounterPagerBackdrop(accents: accents, scrollProgress: scrollState.value)
  }
}

/// Full-screen counter backdrop that cross-fades between page palette fills.
///
/// Solid packs keep RGB interpolation. Gradient packs cross-fade the two page
/// styles with opacity so the linear gradients stay intact while paging.
struct CounterPagerBackdrop: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let accents: [CounterAccent]
  let scrollProgress: CGFloat

  var body: some View {
    let sample = Self.backdropSample(
      accents: accents,
      progress: scrollProgress,
      colorScheme: colorScheme,
      reduceMotion: reduceMotion
    )

    Group {
      switch sample {
      case .solid(let color):
        Rectangle().fill(color)
      case .style(let style):
        Rectangle().fill(style)
      case .crossfade(let from, let to, let fraction):
        ZStack {
          Rectangle().fill(from)
          Rectangle().fill(to).opacity(fraction)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  enum BackdropSample {
    case solid(Color)
    case style(AnyShapeStyle)
    case crossfade(from: AnyShapeStyle, to: AnyShapeStyle, fraction: CGFloat)
  }

  static func backdropSample(
    accents: [CounterAccent],
    progress: CGFloat,
    colorScheme: ColorScheme,
    reduceMotion: Bool
  ) -> BackdropSample {
    guard !accents.isEmpty else {
      let palette = CounterAccent.forCustomCounter(at: 0).palette
      return .style(palette.backgroundStyle(for: colorScheme))
    }

    if reduceMotion || accents.count == 1 {
      let index = min(max(Int(round(progress)), 0), accents.count - 1)
      return .style(accents[index].palette.backgroundStyle(for: colorScheme))
    }

    let clamped = min(max(progress, 0), CGFloat(accents.count - 1))
    let lowerIndex = Int(floor(clamped))
    let upperIndex = min(lowerIndex + 1, accents.count - 1)
    let fraction = clamped - CGFloat(lowerIndex)

    let fromPalette = accents[lowerIndex].palette
    let toPalette = accents[upperIndex].palette

    if fromPalette.hasGradient || toPalette.hasGradient {
      if fraction <= 0.001 {
        return .style(fromPalette.backgroundStyle(for: colorScheme))
      }
      if fraction >= 0.999 {
        return .style(toPalette.backgroundStyle(for: colorScheme))
      }
      return .crossfade(
        from: fromPalette.backgroundStyle(for: colorScheme),
        to: toPalette.backgroundStyle(for: colorScheme),
        fraction: fraction
      )
    }

    let from = fromPalette.background(for: colorScheme)
    let to = toPalette.background(for: colorScheme)
    return .solid(Color.interpolated(from: from, to: to, progress: fraction))
  }

  /// Solid-only helper kept for callers that still need a single `Color` sample.
  static func interpolatedBackground(
    accents: [CounterAccent],
    progress: CGFloat,
    colorScheme: ColorScheme,
    reduceMotion: Bool
  ) -> Color {
    guard !accents.isEmpty else {
      return CounterAccent.forCustomCounter(at: 0).palette.background(for: colorScheme)
    }

    if reduceMotion || accents.count == 1 {
      let index = min(max(Int(round(progress)), 0), accents.count - 1)
      return accents[index].palette.background(for: colorScheme)
    }

    let clamped = min(max(progress, 0), CGFloat(accents.count - 1))
    let lowerIndex = Int(floor(clamped))
    let upperIndex = min(lowerIndex + 1, accents.count - 1)
    let fraction = clamped - CGFloat(lowerIndex)

    let from = accents[lowerIndex].palette.background(for: colorScheme)
    let to = accents[upperIndex].palette.background(for: colorScheme)
    return Color.interpolated(from: from, to: to, progress: fraction)
  }
}

extension Color {
  static func interpolated(from: Color, to: Color, progress: CGFloat) -> Color {
    let amount = min(max(progress, 0), 1)

#if canImport(UIKit)
    var fromRed: CGFloat = 0
    var fromGreen: CGFloat = 0
    var fromBlue: CGFloat = 0
    var fromAlpha: CGFloat = 0
    var toRed: CGFloat = 0
    var toGreen: CGFloat = 0
    var toBlue: CGFloat = 0
    var toAlpha: CGFloat = 0

    guard
      UIColor(from).getRed(&fromRed, green: &fromGreen, blue: &fromBlue, alpha: &fromAlpha),
      UIColor(to).getRed(&toRed, green: &toGreen, blue: &toBlue, alpha: &toAlpha)
    else {
      return amount < 0.5 ? from : to
    }

    return Color(
      red: fromRed + (toRed - fromRed) * amount,
      green: fromGreen + (toGreen - fromGreen) * amount,
      blue: fromBlue + (toBlue - fromBlue) * amount,
      opacity: fromAlpha + (toAlpha - fromAlpha) * amount
    )
#else
    return amount < 0.5 ? from : to
#endif
  }
}
