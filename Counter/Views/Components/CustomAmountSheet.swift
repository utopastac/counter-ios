import SwiftUI

struct CustomAmountSheet: View {
  let onAdd: (Int) -> Void

  var body: some View {
    AmountEntrySheet(
      title: "Add amount",
      headerIcon: .plus,
      actionTitle: "Add",
      onSubmit: onAdd
    )
    .environment(\.counterAccent, nil)
    .counterDesignSystemFromColorScheme()
  }
}

#Preview {
  Text("Preview")
    .sheet(isPresented: .constant(true)) {
      CustomAmountSheet { _ in }
    }
}
