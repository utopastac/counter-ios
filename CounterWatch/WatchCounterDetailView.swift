import SwiftUI
import SwiftData

struct WatchCounterDetailView: View {
  @Bindable var counter: CustomCounter
  @Environment(\.modelContext) private var modelContext

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

        WatchQuickAddGrid(values: counter.buttonValues) { value in
          addEntryQuick(value)
        }
      }
      .padding(.horizontal, 4)
    }
    .navigationTitle(counter.name)
  }

  private var heroValue: String {
    counter.currentProgress().map { progress in
      switch counter.goalDirection {
      case .countUp:
        return "\(progress.current)/\(progress.goal)"
      case .countDown:
        return "\(progress.heroValue)"
      }
    } ?? "\(periodTotal)"
  }

  private func addEntryQuick(_ value: Int) {
    EntryActions.addCounterEntryQuick(value: value, counter: counter, in: modelContext)
  }
}

#Preview {
  NavigationStack {
    WatchCounterDetailView(counter: CustomCounter(name: "Protein"))
  }
  .modelContainer(for: [CustomCounter.self, CounterEntry.self], inMemory: true)
}
