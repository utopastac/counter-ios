import SwiftUI

/// Tappable entry preview that zooms into a full-screen log via iOS 18 `navigationTransition`.
struct EntryLogHeroLink<Preview: View, Destination: View>: View {
  @Namespace private var heroNamespace
  @Binding var isExpanded: Bool

  let heroID: String
  @ViewBuilder var preview: () -> Preview
  @ViewBuilder var destination: () -> Destination

  var body: some View {
    Button {
      isExpanded = true
    } label: {
      preview()
        .matchedTransitionSource(id: heroID, in: heroNamespace) { source in
          source
            .clipShape(RoundedRectangle(cornerRadius: RadiusToken.lg, style: .continuous))
        }
    }
    .buttonStyle(.noHighlight)
    .navigationDestination(isPresented: $isExpanded) {
      destination()
        .navigationTransition(.zoom(sourceID: heroID, in: heroNamespace))
    }
  }
}
