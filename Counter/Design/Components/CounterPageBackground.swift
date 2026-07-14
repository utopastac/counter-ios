import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Per-page counter backdrop that scrolls with its counter.
struct CounterPageBackground: View {
  @Environment(\.semanticColors) private var colors

  var body: some View {
    colors.surfaceCounterBackground
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

/// Full-screen counter backdrop that cross-fades between page palette colors.
struct CounterPagerBackdrop: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let accents: [CounterAccent]
  let scrollProgress: CGFloat

  var body: some View {
    Rectangle()
      .fill(interpolatedBackground)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var interpolatedBackground: Color {
    CounterPagerBackdrop.interpolatedBackground(
      accents: accents,
      progress: scrollProgress,
      colorScheme: colorScheme,
      reduceMotion: reduceMotion
    )
  }

  static func interpolatedBackground(
    accents: [CounterAccent],
    progress: CGFloat,
    colorScheme: ColorScheme,
    reduceMotion: Bool
  ) -> Color {
    guard !accents.isEmpty else {
      return CounterAccent.calories.palette.background(for: colorScheme)
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
