import SwiftUI

/// Settings sheet for choosing a font pack — same card-grid pattern as colour packs.
struct FontPackPickerView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.semanticColors) private var colors

  @Binding var selection: FontPack

  var body: some View {
    VStack(spacing: 0) {
      CounterSheetHeader(title: "Select a font pack") {
        dismiss()
      }

      ScrollView {
        FontPackPickerGrid(selection: $selection)
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
  FontPackPickerView(selection: .constant(.default))
}
