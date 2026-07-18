import SwiftUI
import SwiftData

struct WatchCounterPagerView: View {
  @Query(sort: \CustomCounter.sortOrder) private var counters: [CustomCounter]

  var body: some View {
    Group {
      if counters.isEmpty {
        ContentUnavailableView(
          "Nothing yet",
          systemImage: "number.square",
          description: Text("Add one on iPhone")
        )
      } else {
        NavigationStack {
          TabView {
            ForEach(counters) { counter in
              WatchCounterPageView(counter: counter)
            }
          }
          .tabViewStyle(.verticalPage)
        }
      }
    }
  }
}

#Preview {
  WatchCounterPagerView()
    .modelContainer(for: CustomCounter.self, inMemory: true)
}
