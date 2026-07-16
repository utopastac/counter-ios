import SwiftUI

/// Small-widget-only counterpart to `WidgetHeroHeading`: title, hero number, and subtitle each
/// get their own line instead of folding the title into the headline, since a small widget
/// isn't wide enough to keep a combined "value + title" line legible at a useful size.
struct WidgetSmallHeroStack: View {
  let title: String
  let heroValue: String
  let subtitle: String
  let foreground: Color

  var body: some View {
    VStack(alignment: .leading, spacing: -2) {
      Text(title)
        .font(WidgetTheme.smallTitleFont)
        .tracking(WidgetTheme.smallTitleTracking)
        .foregroundStyle(foreground)
        .lineLimit(1)
        .minimumScaleFactor(0.7)

      Text(heroValue)
        .font(WidgetTheme.smallValueFont)
        .tracking(WidgetTheme.smallValueTracking)
        .foregroundStyle(foreground)
        .lineLimit(1)
        .minimumScaleFactor(0.6)

      Text(subtitle)
        .font(WidgetTheme.subtitleFont)
        .tracking(WidgetTheme.subtitleTracking)
        .foregroundStyle(foreground)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
