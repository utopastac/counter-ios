import SwiftUI

enum CounterLucideIconName: String {
  case listSortDescending = "lucide-list-sort-descending"
  case chartBar = "lucide-chart-no-axes-column"
  case slidersHorizontal = "lucide-sliders-horizontal"
  case plus = "lucide-plus"
  case chevronRight = "lucide-chevron-right"
  case ellipsis = "lucide-ellipsis"
  case deleteBackward = "lucide-delete"
  case maximize2 = "lucide-maximize-2"
  case arrowUpToLine = "lucide-arrow-up-to-line"
  case calendar = "lucide-calendar"
  case listRestart = "lucide-list-restart"
  case chevronsUpDown = "lucide-chevrons-up-down"
  case cog = "lucide-cog"
  case undo2 = "lucide-undo-2"
}

struct CounterLucideIcon: View {
  let icon: CounterLucideIconName
  var color: Color?
  var size: CGFloat = SizeToken.iconGlyph

  var body: some View {
    Image(icon.rawValue)
      .renderingMode(.template)
      .resizable()
      .interpolation(.high)
      .antialiased(true)
      .aspectRatio(contentMode: .fit)
      .frame(width: size, height: size)
      .foregroundStyle(color ?? .primary)
      .accessibilityHidden(true)
  }
}
