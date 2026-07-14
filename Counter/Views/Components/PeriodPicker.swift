import SwiftUI

struct PeriodPicker: View {
  @Binding var selection: HistoryPeriod

  var body: some View {
    HistoryPeriodPicker(selection: $selection)
  }
}

#Preview {
  PeriodPicker(selection: .constant(.daily))
    .padding()
    .counterDesignSystem(CounterDesignSystem(colorScheme: .light, accent: nil))
}
