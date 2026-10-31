import SwiftUI

/// Settings sheet for choosing a colour pack — same card grid as fresh-install step 1.
struct ColorPackPickerView: View {
  @Binding var selection: CounterColorPack

  var body: some View {
    CounterSheetScroll(title: "Select a color pack") {
      ColorPackPickerGrid(selection: $selection)
        .padding(.horizontal, SheetToken.horizontal)
        .padding(.bottom, SpaceToken.u4)
    }
    .counterDesignSystemFromAppearancePreference()
    .counterSheetPresentation()
  }
}

#Preview {
  ColorPackPickerView(selection: .constant(.muted))
}
