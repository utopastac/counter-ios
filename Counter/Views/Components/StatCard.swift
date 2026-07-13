import SwiftUI

struct StatCard: View {
  let title: String
  let value: String
  let subtitle: String?
  let color: Color

  init(title: String, value: String, subtitle: String? = nil, color: Color = .accentColor) {
    self.title = title
    self.value = value
    self.subtitle = subtitle
    self.color = color
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(value)
        .font(.title2.bold())
        .foregroundStyle(color)
      if let subtitle {
        Text(subtitle)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(color.opacity(0.08))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

#Preview {
  StatCard(title: "Active", value: "420", subtitle: "kcal burned")
    .padding()
}
