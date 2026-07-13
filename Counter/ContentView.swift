import SwiftUI

struct ContentView: View {
  var body: some View {
    CounterPagerView()
      .counterDesignSystemFromColorScheme()
  }
}

#Preview {
  PreviewModel.appRoot {
    ContentView()
  }
}
