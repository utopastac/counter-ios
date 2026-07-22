import SwiftUI

/// Two-column grid of colour-pack cards with mini swatches.
/// Shared by fresh-install onboarding and global settings.
struct ColorPackPickerGrid: View {
  @Environment(\.semanticColors) private var colors
  @Environment(\.colorScheme) private var colorScheme

  @Binding var selection: CounterColorPack

  private var packColumns: [GridItem] {
    [
      GridItem(.flexible(), spacing: OnboardingToken.optionGap),
      GridItem(.flexible(), spacing: OnboardingToken.optionGap),
    ]
  }

  private var swatchColumns: [GridItem] {
    Array(
      repeating: GridItem(.flexible(), spacing: OnboardingToken.swatchGap),
      count: 5
    )
  }

  var body: some View {
    LazyVGrid(columns: packColumns, spacing: OnboardingToken.optionGap) {
      ForEach(CounterColorPack.allCases) { pack in
        packCard(pack)
      }
    }
  }

  private func packCard(_ pack: CounterColorPack) -> some View {
    let isSelected = selection == pack

    return Button {
      selection = pack
    } label: {
      VStack(alignment: .leading, spacing: OnboardingToken.titleToSwatches) {
        Text(pack.label)
          .counterTextStyle(.settingsRowLabel)

        LazyVGrid(columns: swatchColumns, spacing: OnboardingToken.swatchGap) {
          ForEach(Array(pack.entries.enumerated()), id: \.offset) { _, entry in
            RoundedRectangle(
              cornerRadius: SizeToken.onboardingSwatchCorner,
              style: .continuous
            )
            .fill(swatchStyle(for: entry, pack: pack))
            .aspectRatio(1, contentMode: .fit)
          }
        }
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
  }

  private func swatchStyle(
    for entry: CounterPaletteColorData,
    pack: CounterColorPack
  ) -> AnyShapeStyle {
    entry.backgroundStyle(for: pack.resolvedScheme(for: colorScheme))
  }
}
