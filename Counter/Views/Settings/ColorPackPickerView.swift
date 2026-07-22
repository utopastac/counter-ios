import SwiftUI

/// Settings sheet for choosing a colour pack — same card grid as fresh-install step 1.
struct ColorPackPickerView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.semanticColors) private var colors

  @Binding var selection: CounterColorPack

  var body: some View {
    VStack(spacing: 0) {
      CounterSheetHeader(title: "Select a color pack") {
        dismiss()
      }

      ScrollView {
        ColorPackPickerGrid(selection: $selection)
          .padding(.horizontal, SheetToken.horizontal)
          .padding(.top, SpaceToken.u2)
          .padding(.bottom, SpaceToken.u4)
      }
    }
    .background(colors.surfacePrimary)
    .counterDesignSystemFromAppearancePreference()
    .counterSheetPresentation()
  }
}

#Preview {
  ColorPackPickerView(selection: .constant(.muted))
}
