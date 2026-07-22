import SwiftUI
import SwiftData

struct WatchQuickAddView: View {
  @Bindable var counter: CustomCounter
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @State private var quickAddStore = QuickAddSessionStore()

  var body: some View {
    VStack(spacing: 8) {
      header
        .padding(.horizontal, 4)

      WatchQuickAddGrid(
        values: counter.presetAmounts,
        defaultPresets: QuickAddConfiguration.defaultPresets(forCounterNamed: counter.name)
      ) { value in
        addEntryQuick(value)
      }
      .padding(.horizontal, 2)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(Color.black.ignoresSafeArea())
    .navigationBarHidden(true)
  }

  private var header: some View {
    HStack(alignment: .center, spacing: 8) {
      Button {
        dismiss()
      } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.white)
          .frame(width: 36, height: 36)
          .background(Color.white.opacity(0.14), in: Circle())
      }
      .buttonStyle(.plain)

      Spacer(minLength: 0)

      Text(CounterFormatting.amount(counter.currentTotal()))
        .font(.system(size: 34, weight: .bold, design: .rounded))
        .foregroundStyle(.white)
        .monospacedDigit()
        .contentTransition(.numericText())
        .animation(.snappy, value: counter.currentTotal())
    }
  }

  private func addEntryQuick(_ value: Double) {
    quickAddStore.addCounterEntryQuick(value: value, counter: counter, in: modelContext)
    AppHaptics.impact()
    AppSounds.log()
  }
}

#Preview {
  NavigationStack {
    WatchQuickAddView(counter: CustomCounter(name: "Calories"))
  }
  .modelContainer(for: [CustomCounter.self, CounterEntry.self], inMemory: true)
}
