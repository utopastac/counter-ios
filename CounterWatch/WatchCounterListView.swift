import SwiftUI
import SwiftData

struct WatchCounterListView: View {
  @Query(sort: \CustomCounter.createdAt) private var counters: [CustomCounter]

  var body: some View {
    NavigationStack {
      Group {
        if counters.isEmpty {
          ContentUnavailableView(
            "No Counters",
            systemImage: "number.square",
            description: Text("Create counters on iPhone")
          )
        } else {
          List(counters) { counter in
            NavigationLink {
              WatchCounterDetailView(counter: counter)
            } label: {
              HStack {
                Text(counter.name)
                Spacer()
                Text("\(todayTotal(for: counter))")
                  .foregroundStyle(.secondary)
              }
            }
          }
        }
      }
      .navigationTitle("Counters")
    }
  }

  private func todayTotal(for counter: CustomCounter) -> Int {
    HistoryAggregator.counterTotal(from: counter.entries, on: .now)
  }
}

#Preview {
  WatchCounterListView()
    .modelContainer(for: CustomCounter.self, inMemory: true)
}
