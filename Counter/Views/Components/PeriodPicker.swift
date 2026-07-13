import SwiftUI

struct PeriodPicker: View {
  @Binding var selection: HistoryPeriod

  var body: some View {
    Picker("Period", selection: $selection) {
      ForEach(HistoryPeriod.allCases) { period in
        Text(period.title).tag(period)
      }
    }
    .pickerStyle(.segmented)
  }
}

#Preview {
  PeriodPicker(selection: .constant(.daily))
    .padding()
}
