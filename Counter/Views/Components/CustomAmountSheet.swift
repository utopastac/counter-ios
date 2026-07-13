import SwiftUI

struct CustomAmountSheet: View {
  @Environment(\.dismiss) private var dismiss

  let onAdd: (Int) -> Void

  @State private var amountText = ""
  @FocusState private var isFocused: Bool

  var body: some View {
    NavigationStack {
      Form {
        TextField("Amount", text: $amountText)
          .keyboardType(.numberPad)
          .focused($isFocused)
      }
      .navigationTitle("Custom Amount")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Add") {
            guard let value = parsedValue else { return }
            onAdd(value)
            dismiss()
          }
          .disabled(parsedValue == nil)
        }
      }
      .onAppear {
        isFocused = true
      }
    }
    .presentationDetents([.medium])
  }

  private var parsedValue: Int? {
    guard let value = Int(amountText.trimmingCharacters(in: .whitespaces)), value > 0 else {
      return nil
    }
    return value
  }
}

#Preview {
  Text("Preview")
    .sheet(isPresented: .constant(true)) {
      CustomAmountSheet { _ in }
    }
}
