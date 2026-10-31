import SwiftUI

/// Settings sheet for choosing a font pack — same card-grid pattern as colour packs.
struct FontPackPickerView: View {
  @Binding var selection: FontPack

  var body: some View {
    CounterSheetScroll(title: "Select a font pack") {
      FontPackPickerGrid(selection: $selection)
        .padding(.horizontal, SheetToken.horizontal)
        .padding(.bottom, SpaceToken.u4)
    }
    .counterDesignSystemFromAppearancePreference()
    .counterSheetPresentation()
  }
}

#Preview {
  FontPackPickerView(selection: .constant(.default))
}
