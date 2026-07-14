import SwiftUI

struct CounterToggle: View {
  @Environment(\.semanticColors) private var colors

  @Binding var isOn: Bool

  private var thumbExtent: CGFloat {
    SizeToken.toggleHeight - SizeToken.toggleThumbPadding * 2
  }

  var body: some View {
    Button {
      withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
        isOn.toggle()
      }
    } label: {
      ZStack(alignment: isOn ? .trailing : .leading) {
        Capsule(style: .continuous)
          .fill(ComponentColor.toggleTrackFill(colors))
          .frame(width: SizeToken.toggleWidth, height: SizeToken.toggleHeight)

        Capsule(style: .continuous)
          .fill(ComponentColor.toggleThumbFill(colors))
          .frame(width: thumbExtent, height: thumbExtent)
          .padding(SizeToken.toggleThumbPadding)
      }
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(.isButton)
    .accessibilityValue(isOn ? "On" : "Off")
  }
}

struct SettingsToggleRow: View {
  let label: String
  @Binding var isOn: Bool

  var body: some View {
    HStack(spacing: SpaceToken.u2) {
      Text(label)
        .counterTextStyle(.settingsRowLabel)

      Spacer(minLength: SpaceToken.u1)

      CounterToggle(isOn: $isOn)
    }
    .padding(.vertical, SpaceToken.u2)
  }
}

#Preview {
  struct PreviewContainer: View {
    @State private var isOn = false

    var body: some View {
      SettingsToggleRow(label: "Dark mode", isOn: $isOn)
        .padding()
        .counterDesignSystem(CounterDesignSystem(colorScheme: .dark, accent: nil))
    }
  }

  return PreviewContainer()
}
