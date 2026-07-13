import SwiftUI

struct GlassCard<Content: View>: View {
  @ViewBuilder var content: () -> Content

  var body: some View {
    content()
      .padding(.horizontal, SpaceToken.x4)
      .padding(.vertical, SpaceToken.x3 + 2)
      .glassSurface(variant: .fillSubtle, cornerRadius: RadiusToken.lg)
  }
}
