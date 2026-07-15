import SwiftUI
import SwiftData

struct WatchCounterListView: View {
  @Query(sort: \CustomCounter.createdAt) private var counters: [CustomCounter]

  var body: some View {
    NavigationStack {
      Group {
        if counters.isEmpty {
          ContentUnavailableView(
            "Nothing yet",
            systemImage: "number.square",
            description: Text("Add one on iPhone")
          )
        } else {
          List(counters) { counter in
            NavigationLink {
              WatchCounterDetailView(counter: counter)
            } label: {
              HStack {
                Text(counter.name)
                Spacer()
                // Uses the counter's own reset period (not just "today") so this total always
                // agrees with the period total shown in `WatchCounterDetailView` for weekly/monthly counters.
                Text("\(counter.currentTotal())")
                  .foregroundStyle(.secondary)
              }
            }
          }
        }
      }
    }
  }
}

#Preview {
  WatchCounterListView()
    .modelContainer(for: CustomCounter.self, inMemory: true)
}
