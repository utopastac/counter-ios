import SwiftUI
import Testing

struct CounterColorPackTests {
  private var gradientPacks: Set<CounterColorPack> {
    [
      .gradient, .aurora, .dusk, .nebula, .twilight,
      .bloom, .dawn, .water, .sheen,
    ]
  }

  private var alwaysDarkPacks: Set<CounterColorPack> {
    [.aurora, .dusk, .nebula, .twilight]
  }

  private var alwaysLightPacks: Set<CounterColorPack> {
    [.bloom, .dawn, .water]
  }

  @Test func everyPackHasExactlyTenNamedSlots() {
    for pack in CounterColorPack.allCases {
      #expect(pack.entries.count == CounterPaletteData.slotCount)
      #expect(pack.entries.allSatisfy { !$0.name.isEmpty })

      let names = pack.entries.map(\.name)
      #expect(Set(names).count == names.count, "\(pack.label) has duplicate slot names")
    }
  }

  @Test func labelsAndRawValuesAreUniqueAndNonEmpty() {
    let labels = CounterColorPack.allCases.map(\.label)
    let rawValues = CounterColorPack.allCases.map(\.rawValue)

    #expect(labels.allSatisfy { !$0.isEmpty })
    #expect(rawValues.allSatisfy { !$0.isEmpty })
    #expect(Set(labels).count == labels.count)
    #expect(Set(rawValues).count == rawValues.count)
  }

  @Test func rgbComponentsStayInUnitRange() {
    for pack in CounterColorPack.allCases {
      for entry in pack.entries {
        assertRGBInRange(entry.lightRGB, pack: pack, slot: entry.name, field: "lightRGB")
        assertRGBInRange(entry.darkRGB, pack: pack, slot: entry.name, field: "darkRGB")
        for stop in entry.lightGradient ?? [] {
          assertRGBInRange(stop, pack: pack, slot: entry.name, field: "lightGradient")
        }
        for stop in entry.darkGradient ?? [] {
          assertRGBInRange(stop, pack: pack, slot: entry.name, field: "darkGradient")
        }
      }
    }
  }

  @Test func appearanceLocksMatchExpectedPacks() {
    for pack in CounterColorPack.allCases {
      let expected: CounterColorPackAppearanceLock
      if alwaysDarkPacks.contains(pack) {
        expected = .alwaysDark
      } else if alwaysLightPacks.contains(pack) {
        expected = .alwaysLight
      } else {
        expected = .adaptive
      }

      #expect(pack.appearanceLock == expected)
      #expect(pack.forcesDarkAppearance == (expected == .alwaysDark))
      #expect(pack.forcesLightAppearance == (expected == .alwaysLight))
    }
  }

  @Test func resolvedSchemeHonoursAppearanceLocks() {
    #expect(CounterColorPack.muted.resolvedScheme(for: .light) == .light)
    #expect(CounterColorPack.muted.resolvedScheme(for: .dark) == .dark)

    #expect(CounterColorPack.aurora.resolvedScheme(for: .light) == .dark)
    #expect(CounterColorPack.aurora.resolvedScheme(for: .dark) == .dark)

    #expect(CounterColorPack.water.resolvedScheme(for: .light) == .light)
    #expect(CounterColorPack.water.resolvedScheme(for: .dark) == .light)
  }

  @Test func gradientPacksExposeUsableStopsForTheirLockedScheme() {
    for pack in CounterColorPack.allCases {
      let isGradientPack = gradientPacks.contains(pack)
      #expect(
        pack.entries.allSatisfy(\.hasGradient) == isGradientPack,
        "\(pack.label) gradient membership mismatch"
      )

      guard isGradientPack else { continue }

      let scheme = pack.resolvedScheme(for: .dark)
      for entry in pack.entries {
        #expect(
          entry.linearGradient(for: scheme) != nil,
          "\(pack.label)/\(entry.name) missing gradient for \(scheme)"
        )
      }
    }
  }

  @Test func alwaysDarkGradientPacksUseDarkStops() {
    for pack in alwaysDarkPacks {
      for entry in pack.entries {
        #expect((entry.darkGradient?.count ?? 0) >= 2, "\(pack.label)/\(entry.name)")
      }
    }
  }

  @Test func alwaysLightGradientPacksUseLightStops() {
    for pack in alwaysLightPacks {
      for entry in pack.entries {
        #expect((entry.lightGradient?.count ?? 0) >= 2, "\(pack.label)/\(entry.name)")
      }
    }
  }

  @Test func adaptiveGradientPacksProvideBothSchemes() {
    for pack in [.gradient, .sheen] as [CounterColorPack] {
      for entry in pack.entries {
        #expect((entry.lightGradient?.count ?? 0) >= 2, "\(pack.label)/\(entry.name) light")
        #expect((entry.darkGradient?.count ?? 0) >= 2, "\(pack.label)/\(entry.name) dark")
      }
    }
  }

  @Test func paletteDataEntryWrapsSlotIndices() {
    let previous = AppAppearancePreference.sharedDefaults.string(
      forKey: AppAppearancePreference.colorPackKey
    )
    AppAppearancePreference.sharedDefaults.set(
      CounterColorPack.water.rawValue,
      forKey: AppAppearancePreference.colorPackKey
    )
    defer {
      if let previous {
        AppAppearancePreference.sharedDefaults.set(
          previous,
          forKey: AppAppearancePreference.colorPackKey
        )
      } else {
        AppAppearancePreference.sharedDefaults.removeObject(
          forKey: AppAppearancePreference.colorPackKey
        )
      }
    }

    #expect(CounterPaletteData.selectedPack == .water)
    #expect(CounterPaletteData.entry(at: 0).name == CounterColorPack.water.entries[0].name)
    #expect(CounterPaletteData.entry(at: 10).name == CounterColorPack.water.entries[0].name)
    #expect(CounterPaletteData.entry(at: -1).name == CounterColorPack.water.entries[9].name)
    #expect(CounterPaletteData.resolvedScheme(for: .dark) == .light)
  }

  private func assertRGBInRange(
    _ rgb: CounterPaletteRGB,
    pack: CounterColorPack,
    slot: String,
    field: String
  ) {
    let components = [rgb.red, rgb.green, rgb.blue]
    #expect(
      components.allSatisfy { (0...1).contains($0) },
      "\(pack.label)/\(slot) \(field) out of range: \(components)"
    )
  }
}
