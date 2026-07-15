import Testing

struct CustomCounterModelTests {
  @Test func effectiveGoalIgnoresNilAndNonPositiveValues() {
    let counter = CustomCounter(name: "Water")

    counter.goal = nil
    #expect(counter.effectiveGoal == nil)
    #expect(!counter.hasGoal)

    counter.goal = 0
    #expect(counter.effectiveGoal == nil)

    counter.goal = -10
    #expect(counter.effectiveGoal == nil)

    counter.goal = 50
    #expect(counter.effectiveGoal == 50)
    #expect(counter.hasGoal)
  }

  @Test func effectivePaletteIndexWrapsAroundSlotCount() {
    let counter = CustomCounter(name: "Water", paletteIndex: -3)
    #expect(counter.effectivePaletteIndex == CustomCounter.paletteSlotCount - 3)

    #expect(CustomCounter.normalizedPaletteIndex(0) == 0)
    #expect(CustomCounter.normalizedPaletteIndex(CustomCounter.paletteSlotCount) == 0)
    #expect(CustomCounter.normalizedPaletteIndex(CustomCounter.paletteSlotCount + 5) == 5)
  }

  @Test func effectiveResetAnchorDayClampsPerPeriod() {
    let counter = CustomCounter(name: "Water", resetPeriod: .daily, resetAnchorDay: 99)
    #expect(counter.effectiveResetAnchorDay == 1)

    counter.resetPeriod = .weekly
    counter.resetAnchorDay = 99
    #expect(counter.effectiveResetAnchorDay == 7)

    counter.resetAnchorDay = 0
    #expect(counter.effectiveResetAnchorDay == 1)

    counter.resetPeriod = .monthly
    counter.resetAnchorDay = 99
    #expect(counter.effectiveResetAnchorDay == 31)
  }

  @Test func effectiveSliderMaxFallsBackWhenNonPositive() {
    let counter = CustomCounter(name: "Water", sliderMax: 0)
    #expect(counter.effectiveSliderMax == 100)

    counter.sliderMax = 250
    #expect(counter.effectiveSliderMax == 250)
  }

  @Test func defaultButtonValuesAreUsedWhenNoneProvided() {
    let counter = CustomCounter(name: "Water")
    #expect(counter.buttonValues == CustomCounter.defaultButtonValues)
  }
}
