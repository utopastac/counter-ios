import SwiftUI

struct CustomAmountInput: View {
  let onAdd: (Int) -> Void

  @State private var amountText = ""

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Custom amount")
        .font(.caption.weight(.semibold))
        .tracking(1.1)
        .foregroundStyle(.white.opacity(0.55))

      HStack(spacing: 12) {
        TextField("0", text: $amountText)
          .keyboardType(.numberPad)
          .textFieldStyle(.plain)
          .font(.title3.weight(.semibold).monospacedDigit())
          .foregroundStyle(.white)
          .padding(.vertical, 14)
          .padding(.horizontal, 16)
          .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .strokeBorder(.white.opacity(0.12), lineWidth: 1)
          )

        Button {
          guard let value = parsedValue else { return }
          onAdd(value)
          amountText = ""
        } label: {
          Text("Add")
            .font(.headline)
            .frame(width: 76)
            .padding(.vertical, 16)
            .background(canAdd ? Color.white : Color.white.opacity(0.25), in: Capsule())
            .foregroundStyle(canAdd ? Color.black : Color.white.opacity(0.45))
        }
        .buttonStyle(.plain)
        .disabled(!canAdd)
      }
    }
  }

  private var parsedValue: Int? {
    guard let value = Int(amountText.trimmingCharacters(in: .whitespaces)), value > 0 else {
      return nil
    }
    return value
  }

  private var canAdd: Bool {
    parsedValue != nil
  }
}

#Preview {
  ZStack {
    CounterPagerBackdrop(accents: [.calories], scrollProgress: 0)
    CustomAmountInput { _ in }
      .padding()
  }
  .counterDesignSystem(CounterDesignSystem(colorScheme: .dark, accent: .calories))
}
