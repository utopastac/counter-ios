import SwiftUI
import SwiftData

struct WatchCounterDetailView: View {
  @Bindable var counter: CustomCounter
  @Environment(\.modelContext) private var modelContext
  @State private var quickAddStore = QuickAddSessionStore()

  private var periodTotal: Int {
    counter.currentTotal()
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 8) {
        Text(heroValue)
          .font(.system(size: 36, weight: .bold, design: .rounded))
        Text(counter.resetPeriod.periodCaption)
          .font(.caption)
          .foregroundStyle(.secondary)

        Divider()

        WatchQuickAddGrid(
          values: counter.buttonValues,
          defaultPresets: QuickAddConfiguration.defaultPresets(forCounterNamed: counter.name)
        ) { value in
          addEntryQuick(value)
        }
      }
      .padding(.horizontal, 4)
    }
    .navigationTitle(counter.name)
  }

  private var heroValue: String {
    counter.currentProgress()?.compactHeroValue ?? "\(periodTotal)"
  }

  private func addEntryQuick(_ value: Int) {
    quickAddStore.addCounterEntryQuick(value: value, counter: counter, in: modelContext)
  }
}

#Preview {
  NavigationStack {
    WatchCounterDetailView(counter: CustomCounter(name: "Protein"))
  }
  .modelContainer(for: [CustomCounter.self, CounterEntry.self], inMemory: true)
}
