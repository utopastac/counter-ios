import SwiftUI
import Testing

struct ProgressRingGlowChoiceTests {
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
      lineWidth: 10
    )
    #expect(pose != nil)
    // Near the top center of the inset circle.
    #expect(abs(pose!.point.x - 50) < 1)
    #expect(pose!.point.y < 50)
  }

  @Test func circlePathIsNonEmptyForPartialAndFullLap() {
    let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
    let partial = ProgressRingGeometry.path(fraction: 0.25, in: rect, lineWidth: 10)
    let full = ProgressRingGeometry.path(fraction: 1, in: rect, lineWidth: 10)
    #expect(!partial.isEmpty)
    #expect(!full.isEmpty)
  }
}
