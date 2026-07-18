import Testing

struct HistoryChartScaleTests {
  @Test func niceMaximumFallsBackToDefaultWhenThereAreNoPositiveValues() {
    #expect(HistoryChartScale.niceMaximum(for: []) == HistoryChartScale.defaultMaximum)
    #expect(HistoryChartScale.niceMaximum(for: [0, 0]) == HistoryChartScale.defaultMaximum)
  }

  @Test func niceMaximumPicksTheSmallestCandidateThatCoversTenPercentHeadroom() {
    // 900 * 1.1 = 990, which is covered by the 1000 candidate.
    #expect(HistoryChartScale.niceMaximum(for: [900]) == 1000)
    // 1200 * 1.1 = 1320, which is covered by the 1500 candidate.
    #expect(HistoryChartScale.niceMaximum(for: [1200]) == 1500)
  }

  @Test func niceMaximumFallsBackToARoundedValueBeyondTheLargestCandidate() {
    let maximum = HistoryChartScale.niceMaximum(for: [20000])
    #expect(maximum == (20000 * 1.1).rounded(.up))
  }

  @Test func tickValuesReturnsZeroForANonPositiveMaximum() {
    #expect(HistoryChartScale.tickValues(maximum: 0) == [0])
  }

  @Test func tickValuesReturnsFourEvenlySpacedTicks() {
    let ticks = HistoryChartScale.tickValues(maximum: 3000)
    #expect(ticks == [0, 1000, 2000, 3000])
  }

  @Test func formattedTickRoundsToWholeNumbers() {
    #expect(HistoryChartScale.formattedTick(499.6) == "500")
    #expect(HistoryChartScale.formattedTick(833.333) == "833")
    #expect(HistoryChartScale.formattedTick(0) == "0")
    #expect(HistoryChartScale.formattedTick(500) == "500")
  }
}
