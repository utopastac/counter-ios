import Testing

struct QuickAddConfigurationTests {
  @Test func normalizedPresetsSortsAndCapsAtPresetCount() {
    let values: [Double] = [100, 1, 50, 20, 10, 5, 2, 75, 25, 999]
    let normalized = QuickAddConfiguration.normalizedPresets(values)

    #expect(normalized.count == QuickAddConfiguration.presetCount)
    #expect(normalized == normalized.sorted())
  }

  @Test func filledPresetsKeepsExistingValuesUntouched() {
    let stored: [Double] = [10, 20, 30]
    let filled = QuickAddConfiguration.filledPresets(from: stored, defaults: QuickAddConfiguration.defaultCounterPresets)

    #expect(Set(stored).isSubset(of: Set(filled)))
  }

  @Test func filledPresetsPadsUpToPresetCountWithoutDuplicates() {
    let stored: [Double] = [10]
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

  // MARK: - defaultPresets(forCounterNamed:)

  @Test func defaultPresetsForCounterNamedUsesCaloriePresetsCaseInsensitively() {
    #expect(QuickAddConfiguration.defaultPresets(forCounterNamed: "Calories") == QuickAddConfiguration.defaultCaloriePresets)
    #expect(QuickAddConfiguration.defaultPresets(forCounterNamed: "CALORIES") == QuickAddConfiguration.defaultCaloriePresets)
  }

  @Test func presetsReplacingLegacyCalorieDuplicateSwapsTheSecondFiftyForEighty() {
    let legacy: [Double] = [5, 10, 25, 50, 50, 100, 200, 500, 1000]
    let updated = QuickAddConfiguration.presetsReplacingLegacyCalorieDuplicate(legacy)

    #expect(updated == QuickAddConfiguration.defaultCaloriePresets)
    #expect(updated.contains(80))
    #expect(updated.filter { $0 == 50 }.count == 1)
  }

  @Test func presetsReplacingLegacyCalorieDuplicateLeavesCustomizedListsAlone() {
    let custom: [Double] = [5, 10, 25, 50, 50, 100, 200, 500, 250]
    #expect(QuickAddConfiguration.presetsReplacingLegacyCalorieDuplicate(custom) == custom)
  }

  @Test func defaultPresetsForCounterNamedFallsBackToGenericPresetsForOtherNames() {
    #expect(QuickAddConfiguration.defaultPresets(forCounterNamed: "Protein") == QuickAddConfiguration.defaultCounterPresets)
  }

  // MARK: - replacingPreset

  @Test func replacingPresetSwapsAnExistingValueInPlace() {
    let updated = QuickAddConfiguration.replacingPreset(20, with: 30, in: [10, 20, 50])
    #expect(updated == [10, 30, 50])
  }

  @Test func replacingPresetAppendsWhenTheOldValueIsNotStoredAndThereIsRoom() {
    // 20 isn't in `values` (it's only ever shown via `filledPresets`' fallback), so editing it
    // should append the new value rather than silently doing nothing.
    let updated = QuickAddConfiguration.replacingPreset(20, with: 15, in: [10])
    #expect(updated.contains(15))
    #expect(updated.count == 2)
  }

  @Test func replacingPresetIgnoresNonPositiveInput() {
    let updated = QuickAddConfiguration.replacingPreset(20, with: 0, in: [10, 20, 50])
    #expect(updated == [10, 20, 50])
  }

  @Test func replacingPresetDoesNotExceedPresetCountWhenAppending() {
    let full = (1...QuickAddConfiguration.presetCount).map(Double.init)
    let updated = QuickAddConfiguration.replacingPreset(999, with: 1000, in: full)
    #expect(updated.count == QuickAddConfiguration.presetCount)
    #expect(!updated.contains(1000))
  }

  // MARK: - widgetButtonValues

  @Test func widgetButtonValuesDedupesPreservingOrderAndCapsAtWidgetCount() {
    let presets: [Double] = [5, 10, 5, 25, 50, 100, 200, 500, 1000, 80, 15]
    let values = QuickAddConfiguration.widgetButtonValues(from: presets)

    #expect(values.count == QuickAddConfiguration.widgetButtonCount)
    #expect(values == [5, 10, 25, 50, 100, 200, 500, 1000])
    #expect(values.count == Set(values).count)
  }

  @Test func widgetButtonValuesLeavesShortListsUntouched() {
    let presets: [Double] = [1, 2, 5]
    #expect(QuickAddConfiguration.widgetButtonValues(from: presets) == presets)
  }
}

