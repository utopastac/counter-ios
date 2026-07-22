import SwiftUI
import Testing

struct ProgressRingStyleTests {
  @Test func labelsAreTitleCased() {
    #expect(ProgressRingStyle.solid.label == "Solid")
    #expect(ProgressRingStyle.square.label == "Square")
    #expect(ProgressRingStyle.hexagon.label == "Hexagon")
  }

  @Test func tipFlags() {
    for style in ProgressRingStyle.allCases {
      #expect(style.showsTip)
    }
  }

  @Test func polygonStylesExposeSideCounts() {
    #expect(ProgressRingStyle.solid.ringSides == nil)
    #expect(ProgressRingStyle.square.ringSides == 4)
    #expect(ProgressRingStyle.hexagon.ringSides == 6)
    #expect(ProgressRingStyle.square.usesFlatTip)
    #expect(ProgressRingStyle.hexagon.usesFlatTip)
    #expect(!ProgressRingStyle.solid.usesFlatTip)
  }

  @Test func solidUsesRoundCaps() {
    let solid = ProgressRingStyle.solid.strokeStyle(lineWidth: 10)
    #expect(solid.lineCap == .round)
    #expect(solid.dash.isEmpty)
  }

  @Test func polygonStylesUseButtCaps() {
    for style: ProgressRingStyle in [.square, .hexagon] {
      let stroke = style.strokeStyle(lineWidth: 10)
      #expect(stroke.lineCap == .butt)
      #expect(stroke.lineJoin == .miter)
    }
  }

  @Test func unknownRawValueFallsBackToSolid() {
    #expect((ProgressRingStyle(rawValue: "dashed") ?? .solid) == .solid)
    #expect((ProgressRingStyle(rawValue: "glow") ?? .solid) == .solid)
  }

  @Test func styleChoiceMigratesRetiredGlowCase() {
    #expect(ProgressRingStyleChoice(storedRaw: "glow") == .solid)
    #expect(ProgressRingStyleChoice(storedRaw: "glow").storedRaw == ProgressRingStyle.solid.rawValue)
  }

  @Test func glowChoiceStoresOverride() {
    #expect(ProgressRingGlowChoice.default.overrideEnabled == nil)
    #expect(ProgressRingGlowChoice.on.overrideEnabled == true)
    #expect(ProgressRingGlowChoice.off.overrideEnabled == false)
    #expect(ProgressRingGlowChoice(storedRaw: nil) == .default)
    #expect(ProgressRingGlowChoice(storedRaw: "on").storedRaw == "on")
  }
}

struct ProgressRingGeometryTests {
  @Test func circleTipStartsAtTwelveOClock() {
    let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
    let pose = ProgressRingGeometry.tipPose(
      fraction: 0.0001,
      in: rect,
      lineWidth: 10,
      sides: nil
    )
    #expect(pose != nil)
    // Near the top center of the inset circle.
    #expect(abs(pose!.point.x - 50) < 1)
    #expect(pose!.point.y < 50)
  }

  @Test func squarePathStartsOnTopEdge() {
    let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
    let path = ProgressRingGeometry.path(fraction: 0.01, in: rect, lineWidth: 10, sides: 4)
    #expect(!path.isEmpty)
    let tip = ProgressRingGeometry.tipPose(fraction: 0.01, in: rect, lineWidth: 10, sides: 4)
    #expect(tip != nil)
    // Early progress stays on the top edge (near min Y of the inset square).
    #expect(tip!.point.y < 40)
  }

  @Test func hexagonExposesSixSidedPerimeter() {
    let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
    let full = ProgressRingGeometry.path(fraction: 1, in: rect, lineWidth: 10, sides: 6)
    let partial = ProgressRingGeometry.path(fraction: 0.5, in: rect, lineWidth: 10, sides: 6)
    #expect(!full.isEmpty)
    #expect(!partial.isEmpty)
  }
}
