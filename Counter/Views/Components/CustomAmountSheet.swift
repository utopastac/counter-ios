import SwiftUI

struct CustomAmountSheet: View {
  let onAdd: (Int) -> Void

  var body: some View {
    AmountEntrySheet(
      title: "Custom Amount",
      actionTitle: "Add",
      onSubmit: onAdd
    )
    .counterDesignSystemFromColorScheme()
  }
}

#Preview {
  Text("Preview")
    .sheet(isPresented: .constant(true)) {
      CustomAmountSheet { _ in }
    }
}
