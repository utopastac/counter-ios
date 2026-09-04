import SwiftUI

/// Motion for the counter hero ↔ stats table swap (full page + compact card).
enum CounterHeaderToggleStyle {
  case hero
  case stats
}

struct CounterHeaderToggleModifier: ViewModifier {
  let style: CounterHeaderToggleStyle
  let isExpanded: Bool
  let reduceMotion: Bool

  func body(content: Content) -> some View {
    switch style {
    case .hero:
      content
        .opacity(isExpanded ? 0 : 1)
        .scaleEffect(
          reduceMotion ? 1 : (isExpanded ? CounterPageToken.headerHeroCollapseScale : 1),
          anchor: .topLeading
        )
        .offset(y: reduceMotion ? 0 : (isExpanded ? CounterPageToken.headerHeroExitOffset : 0))
    case .stats:
      // Opacity + row stagger live on `CounterStatsTable`; keep a light scale so the
      // block still feels like one surface settling into place.
      content
        .scaleEffect(
          reduceMotion ? 1 : (isExpanded ? 1 : 0.98),
          anchor: .topLeading
        )
    }
  }
}

extension View {
  func counterHeaderToggle(
    _ style: CounterHeaderToggleStyle,
    isExpanded: Bool,
    reduceMotion: Bool
  ) -> some View {
    modifier(
      CounterHeaderToggleModifier(
        style: style,
        isExpanded: isExpanded,
        reduceMotion: reduceMotion
      )
    )
  }
}
