import SwiftUI

struct GlassCard<Content: View>: View {
  @ViewBuilder var content: () -> Content

  var body: some View {
    content()
      .padding(.horizontal, SpaceToken.componentPadding)
      .padding(.vertical, SpaceToken.componentPadding)
      .glassSurface(variant: .fillSubtle, cornerRadius: RadiusToken.lg)
  }
}
