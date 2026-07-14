import SwiftUI

struct StatCard: View {
  @Environment(\.semanticColors) private var colors

  let title: String
  let value: String
  let subtitle: String?
  let accent: Color

  init(title: String, value: String, subtitle: String? = nil, accent: Color? = nil) {
    self.title = title
    self.value = value
    self.subtitle = subtitle
    self.accent = accent ?? Color.accentColor
  }

  var body: some View {
    VStack(alignment: .leading, spacing: SpaceToken.x1) {
      Text(title)
        .counterTextStyle(.caption, color: .secondary)
      Text(value)
        .font(.title2.bold())
        .foregroundStyle(accent)
      if let subtitle {
        Text(subtitle)
          .counterTextStyle(.caption2, color: .secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(colors.surfaceTint)
    .clipShape(RadiusToken.continuousSm)
  }
}

#Preview {
  StatCard(title: "Added", value: "420", subtitle: "logged today")
    .padding()
    .counterDesignSystemFromColorScheme()
}
