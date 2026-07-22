import SwiftUI

/// Two-column grid of font-pack cards with a live type preview.
struct FontPackPickerGrid: View {
  @Environment(\.semanticColors) private var colors

  @Binding var selection: FontPack

  private var packColumns: [GridItem] {
    [
      GridItem(.flexible(), spacing: OnboardingToken.optionGap),
      GridItem(.flexible(), spacing: OnboardingToken.optionGap),
    ]
  }

  var body: some View {
    LazyVGrid(columns: packColumns, spacing: OnboardingToken.optionGap) {
      ForEach(FontPack.allCases) { pack in
        packCard(pack)
      }
    }
  }

  private func packCard(_ pack: FontPack) -> some View {
    let isSelected = selection == pack

    return Button {
      selection = pack
    } label: {
      VStack(alignment: .leading, spacing: OnboardingToken.titleToSwatches) {
        Text(pack.label)
          .counterTextStyle(.settingsRowLabel)

        Text("Aa 1234")
          .font(pack.font(size: FontSizeToken.xxl, weight: .semibold))
          .foregroundStyle(colors.textPrimary)
          .lineLimit(1)
          .minimumScaleFactor(0.6)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(OnboardingToken.cardPadding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(colors.surfaceSheet, in: OnboardingToken.cardShape)
      .overlay {
        OnboardingToken.cardShape
          .stroke(
            isSelected ? colors.textPrimary : colors.borderSubtle,
            lineWidth: isSelected
              ? BorderToken.selectionSelected
              : BorderToken.selectionUnselected
          )
      }
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
    .accessibilityLabel(pack.label)
  }
}

#Preview {
  FontPackPickerGrid(selection: .constant(.default))
    .padding()
    .counterDesignSystemFromAppearancePreference()
}
