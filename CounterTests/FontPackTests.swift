import SwiftUI
import Testing

struct FontPackTests {
  @Test func labelsMatchPackNames() {
    #expect(FontPack.default.label == "Default")
    #expect(FontPack.soft.label == "Soft")
    #expect(FontPack.editorial.label == "Editorial")
    #expect(FontPack.technical.label == "Technical")
    #expect(FontPack.geometric.label == "Geometric")
    #expect(FontPack.nineteenTwentySeven.label == "1927")
  }

  @Test func nineteenTwentySevenRawValueIs1927() {
    #expect(FontPack.nineteenTwentySeven.rawValue == "1927")
    #expect(FontPack(rawValue: "1927") == .nineteenTwentySeven)
  }

  @Test func avenirWeightNamesMatchBuiltInFaces() {
    #expect(FontPack.avenirPostScriptName(for: .light) == "Avenir-Light")
    #expect(FontPack.avenirPostScriptName(for: .regular) == "Avenir-Roman")
    #expect(FontPack.avenirPostScriptName(for: .medium) == "Avenir-Medium")
    #expect(FontPack.avenirPostScriptName(for: .semibold) == "Avenir-Heavy")
    #expect(FontPack.avenirPostScriptName(for: .bold) == "Avenir-Heavy")
    #expect(FontPack.avenirPostScriptName(for: .black) == "Avenir-Black")
  }

  @Test func nineteenTwentySevenUsesFuturaMediumOnly() {
    #expect(FontPack.futuraMediumPostScriptName == "Futura-Medium")
    let regular = FontPack.nineteenTwentySeven.font(size: 24, weight: .regular)
    let bold = FontPack.nineteenTwentySeven.font(size: 24, weight: .bold)
    #expect(String(describing: regular) == String(describing: bold))
  }

  @Test func editorialUsesRegularWeightOnly() {
    let regular = FontPack.editorial.font(size: 24, weight: .regular)
    let semibold = FontPack.editorial.font(size: 24, weight: .semibold)
    let bold = FontPack.editorial.font(size: 24, weight: .bold)
    #expect(String(describing: regular) == String(describing: semibold))
    #expect(String(describing: regular) == String(describing: bold))
  }

  @Test func unknownRawValueFallsBackToDefault() {
    #expect((FontPack(rawValue: "handwriting") ?? .default) == .default)
    #expect((FontPack(rawValue: "condensed") ?? .default) == .default)
  }

  @Test func allPacksProduceAFont() {
    for pack in FontPack.allCases {
      let font = pack.font(size: 16, weight: .semibold)
      #expect(String(describing: font).isEmpty == false)
    }
  }
}
