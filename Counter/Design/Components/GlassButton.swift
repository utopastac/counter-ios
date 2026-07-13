import SwiftUI

struct GlassButton: View {
  @Environment(\.semanticColors) private var colors

  let label: String?
  let systemImage: String?
  let action: () -> Void

  init(_ label: String, action: @escaping () -> Void) {
    self.label = label
    self.systemImage = nil
    self.action = action
  }

  init(systemImage: String, action: @escaping () -> Void) {
    self.label = nil
    self.systemImage = systemImage
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      Group {
        if let systemImage {
          Image(systemName: systemImage)
            .counterTextStyle(.iconButton)
        } else if let label {
          Text(label)
            .counterTextStyle(.numericCompact)
        }
      }
      .frame(maxWidth: .infinity)
      .frame(height: SizeToken.quickAddHeight)
      .glassSurface(cornerRadius: RadiusToken.md)
      .foregroundStyle(colors.textPrimary)
    }
    .buttonStyle(.plain)
  }
}

struct GlassIconButton: View {
  @Environment(\.semanticColors) private var colors

  let systemName: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: systemName)
        .counterTextStyle(.iconButton)
        .foregroundStyle(colors.textPrimary)
        .frame(width: SizeToken.iconButton, height: SizeToken.iconButton)
        .glassSurface(cornerRadius: SizeToken.iconButton / 2, shape: .circle)
    }
    .buttonStyle(.plain)
  }
}
