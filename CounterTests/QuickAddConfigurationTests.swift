import Testing

struct QuickAddConfigurationTests {
  @Test func normalizedPresetsSortsAndCapsAtPresetCount() {
    let values = [100, 1, 50, 20, 10, 5, 2, 75, 25, 999]
    let normalized = QuickAddConfiguration.normalizedPresets(values)

    #expect(normalized.count == QuickAddConfiguration.presetCount)
    #expect(normalized == normalized.sorted())
  }

  @Test func filledPresetsKeepsExistingValuesUntouched() {
    let stored = [10, 20, 30]
    let filled = QuickAddConfiguration.filledPresets(from: stored, defaults: QuickAddConfiguration.defaultCounterPresets)

    #expect(Set(stored).isSubset(of: Set(filled)))
  }

  @Test func filledPresetsPadsUpToPresetCountWithoutDuplicates() {
    let stored = [10]
    let filled = QuickAddConfiguration.filledPresets(from: stored, defaults: QuickAddConfiguration.defaultCounterPresets)

    #expect(filled.count == QuickAddConfiguration.presetCount)
    #expect(filled.count == Set(filled).count)
    #expect(filled.contains(10))
  }

  @Test func filledPresetsDoesNotExceedPresetCountWhenAlreadyFull() {
    let stored = Array(QuickAddConfiguration.defaultCounterPresets.prefix(QuickAddConfiguration.presetCount))
    let filled = QuickAddConfiguration.filledPresets(from: stored, defaults: QuickAddConfiguration.defaultCaloriePresets)

    #expect(filled.count == QuickAddConfiguration.presetCount)
  }
}
