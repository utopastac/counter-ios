import SwiftUI

enum GlassSurfaceVariant {
  case fill
  case fillSubtle
}

struct GlassSurfaceModifier: ViewModifier {
  @Environment(\.semanticColors) private var colors

  let variant: GlassSurfaceVariant
  let cornerRadius: CGFloat
  let shape: GlassSurfaceShape

  enum GlassSurfaceShape {
    case roundedRect
    case circle
    case capsule

    @ViewBuilder
    func background<S: ShapeStyle>(_ style: S, cornerRadius: CGFloat) -> some View {
      switch self {
      case .roundedRect:
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .fill(style)
      case .circle:
        Circle().fill(style)
      case .capsule:
        Capsule().fill(style)
      }
    }

    @ViewBuilder
    func stroke(_ color: Color, cornerRadius: CGFloat, lineWidth: CGFloat = 1) -> some View {
      switch self {
      case .roundedRect:
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .strokeBorder(color, lineWidth: lineWidth)
      case .circle:
        Circle().strokeBorder(color, lineWidth: lineWidth)
      case .capsule:
        Capsule().strokeBorder(color, lineWidth: lineWidth)
      }
    }
  }

  func body(content: Content) -> some View {
    content
      .background {
        shape.background(fillColor, cornerRadius: cornerRadius)
      }
      .overlay {
        shape.stroke(strokeColor, cornerRadius: cornerRadius)
      }
  }

  private var fillColor: Color {
    switch variant {
    case .fill:
      return colors.surfaceGlassFill
    case .fillSubtle:
      return colors.surfaceGlassFillSubtle
    }
  }

  private var strokeColor: Color {
    colors.surfaceGlassStroke
  }
}

extension View {
  func glassSurface(
    variant: GlassSurfaceVariant = .fill,
    cornerRadius: CGFloat = RadiusToken.md,
    shape: GlassSurfaceModifier.GlassSurfaceShape = .roundedRect
  ) -> some View {
    modifier(
      GlassSurfaceModifier(
        variant: variant,
        cornerRadius: cornerRadius,
        shape: shape
      )
    )
  }
}
