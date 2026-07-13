import SwiftUI

struct WatchContentView: View {
  var body: some View {
    TabView {
      WatchCalorieView()
        .tabItem {
          Label("Calories", systemImage: "flame.fill")
        }

      WatchCounterListView()
        .tabItem {
          Label("Counters", systemImage: "number.square.fill")
        }
    }
  }
}

#Preview {
  WatchContentView()
    .environment(HealthKitManager())
}
