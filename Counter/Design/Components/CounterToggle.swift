import SwiftUI

struct CounterToggle: View {
  @Environment(\.semanticColors) private var colors

  @Binding var isOn: Bool

  var body: some View {
    Button {
      withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
        isOn.toggle()
      }
    } label: {
      ZStack(alignment: isOn ? .trailing : .leading) {
        RoundedRectangle(cornerRadius: RadiusToken.toggle, style: .continuous)
          .fill(ComponentColor.toggleTrackFill(colors, isOn: isOn))
          .frame(width: SizeToken.toggleWidth, height: SizeToken.toggleHeight)

        RoundedRectangle(cornerRadius: RadiusToken.toggleThumb, style: .continuous)
          .fill(ComponentColor.toggleThumbFill(colors, isOn: isOn))
          .frame(width: SizeToken.toggleThumbWidth, height: SizeToken.toggleThumbHeight)
          .padding(SizeToken.toggleThumbPadding)
      }
      .frame(width: SizeToken.toggleWidth, height: SizeToken.toggleHeight)
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(.isButton)
    .accessibilityValue(isOn ? "On" : "Off")
  }
}

struct SettingsToggleRow: View {
  @Environment(\.semanticColors) private var colors

  let icon: CounterLucideIconName
  let label: String
  @Binding var isOn: Bool

  var body: some View {
    HStack(spacing: SpaceToken.u2) {
      CounterLucideIcon(icon: icon, color: colors.textPrimary)

      Text(label)
        .counterTextStyle(.settingsRowLabel)

      Spacer(minLength: SpaceToken.u1)

      CounterToggle(isOn: $isOn)
    }
    .frame(minHeight: SizeToken.quickAddHeight)
  }
}

#Preview("Light") {
  struct PreviewContainer: View {
    @State private var isOff = false
    @State private var isOn = true

    var body: some View {
      VStack(alignment: .leading, spacing: 16) {
        SettingsToggleRow(icon: .moon, label: "Dark mode", isOn: $isOff)
        SettingsToggleRow(icon: .vibrate, label: "Haptics", isOn: $isOn)
        HStack(spacing: 12) {
          CounterToggle(isOn: $isOff)
          CounterToggle(isOn: $isOn)
        }
      }
      .padding()
      .counterDesignSystem(CounterDesignSystem(colorScheme: .light, accent: nil))
    }
  }

  return PreviewContainer()
}

#Preview("Dark") {
  struct PreviewContainer: View {
    @State private var isOff = false
    @State private var isOn = true

    var body: some View {
      VStack(alignment: .leading, spacing: 16) {
        SettingsToggleRow(icon: .moon, label: "Dark mode", isOn: $isOff)
        SettingsToggleRow(icon: .vibrate, label: "Haptics", isOn: $isOn)
        HStack(spacing: 12) {
          CounterToggle(isOn: $isOff)
          CounterToggle(isOn: $isOn)
        }
      }
      .padding()
      .background(SemanticColors.dark.surfaceSheet)
      .counterDesignSystem(CounterDesignSystem(colorScheme: .dark, accent: nil))
    }
  }

  return PreviewContainer()
}
