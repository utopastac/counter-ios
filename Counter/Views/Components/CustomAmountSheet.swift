import SwiftUI

struct CustomAmountSheet: View {
  let onAdd: (Double) -> Void

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

struct EditAmountSheet: View {
  let initialValue: Double
  let onSave: (Double) -> Void

  var body: some View {
    AmountEntrySheet(
      title: "Edit amount",
      headerIcon: .squarePen,
      actionTitle: "Save",
      initialText: CounterFormatting.editingText(for: initialValue),
      onSubmit: onSave
    )
    .environment(\.counterAccent, nil)
    .counterDesignSystemFromColorScheme()
  }
}

#Preview("Add") {
  Text("Preview")
    .sheet(isPresented: .constant(true)) {
      CustomAmountSheet { _ in }
    }
}

#Preview("Edit") {
  Text("Preview")
    .sheet(isPresented: .constant(true)) {
      EditAmountSheet(initialValue: 150) { _ in }
    }
}
