import Testing

struct AppSoundStyleTests {
  @Test func labelsMatchOptions() {
    #expect(AppSoundStyle.off.label == "Off")
    #expect(AppSoundStyle.soft.label == "Soft")
    #expect(AppSoundStyle.crisp.label == "Crisp")
    #expect(AppSoundStyle.tap.label == "Tap")
  }

  @Test func offDisablesPlayback() {
    #expect(!AppSoundStyle.off.isEnabled)
    #expect(AppSoundStyle.off.logSoundID == nil)
    #expect(AppSoundStyle.off.undoSoundID == nil)
  }

  @Test func enabledStylesProvideSoundIDs() {
    for style in AppSoundStyle.allCases where style.isEnabled {
      #expect(style.logSoundID != nil)
      #expect(style.undoSoundID != nil)
    }
  }

  @Test func unknownRawValueFallsBackToOff() {
    #expect((AppSoundStyle(rawValue: "boom") ?? .off) == .off)
  }
}
