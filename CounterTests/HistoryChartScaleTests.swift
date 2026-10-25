import Testing

struct HistoryChartScaleTests {
  @Test func niceMaximumFallsBackToDefaultWhenThereAreNoPositiveValues() {
    #expect(HistoryChartScale.niceMaximum(for: []) == HistoryChartScale.defaultMaximum)
    #expect(HistoryChartScale.niceMaximum(for: [0, 0]) == HistoryChartScale.defaultMaximum)
    #expect(HistoryChartScale.defaultMaximum == 4)
    #expect(HistoryChartScale.tickValues(maximum: HistoryChartScale.defaultMaximum) == [0, 1, 2, 3, 4])
  }

  @Test func niceMaximumLeavesHeadroomOnARoundCeiling() {
    // 900 * 1.1 = 990, which rounds up to 1,000.
    #expect(HistoryChartScale.niceMaximum(for: [900]) == 1000)
    // 1,200 * 1.1 = 1,320, which rounds up to 1,500.
    #expect(HistoryChartScale.niceMaximum(for: [1200]) == 1500)
  }

  @Test func niceMaximumUsesARoundCeilingPastTenThousand() {
    let maximum = HistoryChartScale.niceMaximum(for: [20000])
    #expect(maximum == 30000)
    #expect(HistoryChartScale.tickValues(maximum: maximum) == [0, 10000, 20000, 30000])
  }

  @Test func smallCountsScaleToTheNextFewIntegers() {
    // One note in the window should not share a calorie-sized axis.
    #expect(HistoryChartScale.niceMaximum(for: [1]) == 2)
    #expect(HistoryChartScale.tickValues(maximum: 2) == [0, 1, 2])

    #expect(HistoryChartScale.niceMaximum(for: [1, 0, 2]) == 3)
    #expect(HistoryChartScale.tickValues(maximum: 3) == [0, 1, 2, 3])
  }

  @Test func tickValuesReturnsZeroForANonPositiveMaximum() {
    #expect(HistoryChartScale.tickValues(maximum: 0) == [0])
  }

  @Test func tickValuesReturnsEvenlySpacedRoundTicks() {
    #expect(HistoryChartScale.tickValues(maximum: 3000) == [0, 1000, 2000, 3000])
    #expect(HistoryChartScale.tickValues(maximum: 1500) == [0, 500, 1000, 1500])
    // 2,500 used to be split into thirds (833, 1,667, 2,500).
    #expect(HistoryChartScale.tickValues(maximum: 2500) == [0, 500, 1000, 1500, 2000, 2500])
  }

  @Test func formattedTickKeepsTheTickAmount() {
    #expect(HistoryChartScale.formattedTick(500) == "500")
    #expect(HistoryChartScale.formattedTick(0) == "0")
    #expect(HistoryChartScale.formattedTick(0.5) == "0.5")
    #expect(HistoryChartScale.formattedTick(1.499999) == "1.5")
  }

  @Test func axisMatchesASmallTargetUntilTheBarsPassIt() {
    // Notes cap of 1: empty and on-target windows both top out at 1.
    #expect(HistoryChartScale.niceMaximum(for: [0, 0], target: 1) == 1)
    #expect(HistoryChartScale.tickValues(maximum: 1, target: 1) == [0, 1])
    #expect(HistoryChartScale.niceMaximum(for: [1], target: 1) == 1)

    // Three notes against a target of 1 grows in whole targets: 0, 1, 2, 3.
    #expect(HistoryChartScale.niceMaximum(for: [1, 3, 0], target: 1) == 3)
    #expect(HistoryChartScale.tickValues(maximum: 3, target: 1) == [0, 1, 2, 3])
  }

  @Test func axisMatchesACalorieTargetInsteadOfSplittingAFixedCeiling() {
    #expect(HistoryChartScale.niceMaximum(for: [400, 1800], target: 2200) == 2200)
    #expect(HistoryChartScale.tickValues(maximum: 2200, target: 2200) == [0, 1100, 2200])

    // Just over the target doubles it, and the target itself stays a gridline.
    #expect(HistoryChartScale.niceMaximum(for: [3000], target: 2200) == 4400)
    #expect(HistoryChartScale.tickValues(maximum: 4400, target: 2200) == [0, 2200, 4400])
  }

  @Test func axisUsesHalvesOfALargerWholeTarget() {
    #expect(HistoryChartScale.niceMaximum(for: [3], target: 8) == 8)
    #expect(HistoryChartScale.tickValues(maximum: 8, target: 8) == [0, 4, 8])
    #expect(HistoryChartScale.tickValues(maximum: 150, target: 150) == [0, 75, 150])
  }
}
