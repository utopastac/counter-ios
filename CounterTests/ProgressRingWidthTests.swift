import Testing

struct ProgressRingWidthTests {
  @Test func ratiosMatchDesignSpec() {
    #expect(ProgressRingWidth.thin.ratio == 0.10)
    #expect(ProgressRingWidth.balanced.ratio == 0.25)
    #expect(ProgressRingWidth.chunky.ratio == 0.40)
  }

  @Test func strokeWidthScalesWithRingSize() {
    #expect(ProgressRingWidth.thin.strokeWidth(for: 100) == 10)
    #expect(ProgressRingWidth.balanced.strokeWidth(for: 96) == 24)
    #expect(ProgressRingWidth.chunky.strokeWidth(for: 100) == 40)
  }

  @Test func labelsAreTitleCased() {
    #expect(ProgressRingWidth.thin.label == "Thin")
    #expect(ProgressRingWidth.balanced.label == "Balanced")
    #expect(ProgressRingWidth.chunky.label == "Chunky")
  }

  @Test func unknownRawValueFallsBackToBalanced() {
    #expect((ProgressRingWidth(rawValue: "nope") ?? .balanced) == .balanced)
  }
}
