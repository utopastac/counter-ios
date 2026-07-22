import SwiftUI

/// Widget counterpart to the app's hero number + subtitle (`HeroMainNumberText` /
/// `HeroSubtitleText` in `Counter/Views/Pager/CounterPageLayout.swift`), folding the counter's
/// title into the headline itself (e.g. `"2424 Calories"`) since the widget has no separate
/// header row to show it in the way the app's pager tabs do.
struct WidgetHeroHeading: View {
  let heroValue: String
  let title: String
  let subtitle: String
  let foreground: Color

  var body: some View {
    VStack(alignment: .leading, spacing: WidgetTheme.heroToSubtitleSpacing) {
      Text("\(heroValue) \(title)")
        .font(WidgetTheme.heroFont)
        .tracking(WidgetTheme.heroTracking)
        .foregroundStyle(foreground)
        .lineLimit(1)

      Text(subtitle)
        .font(WidgetTheme.subtitleFont)
        .tracking(WidgetTheme.subtitleTracking)
        .foregroundStyle(foreground)
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
