import SwiftUI

/// Small-widget-only counterpart to `WidgetHeroHeading`: title, hero number, and subtitle each
/// get their own line instead of folding the title into the headline, since a small widget
/// isn't wide enough to keep a combined "value + title" line legible at a useful size. The
/// progress ring sits above this stack (see `CounterWidgetView.smallLayout`).
struct WidgetSmallHeroStack: View {
  let title: String
  let heroValue: String
  let subtitle: String
  let foreground: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
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
        .padding(.top, WidgetTheme.smallTitleToValueSpacing)

      Text(subtitle)
        .font(WidgetTheme.smallSubtitleFont)
        .tracking(WidgetTheme.smallSubtitleTracking)
        .foregroundStyle(foreground)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.top, WidgetTheme.smallValueToSubtitleSpacing)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
