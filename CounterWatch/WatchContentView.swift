import SwiftUI

struct WatchContentView: View {
  @Environment(\.modelContext) private var modelContext

  var body: some View {
    WatchCounterPagerView()
      .task {
        WatchSyncCoordinator.shared.activate()
        WatchSyncEngine.publishFullSnapshot(in: modelContext)
      }
  }
}

#Preview {
  WatchContentView()
}
