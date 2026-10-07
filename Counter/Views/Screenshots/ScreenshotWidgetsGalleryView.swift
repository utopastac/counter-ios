import SwiftData
import SwiftUI

/// Home Screen–style marketing frame for App Store screenshot capture (`-UITScene 05-widgets`).
///
/// Renders real seeded counters in widget-sized cards (large + two smalls). Not a live
/// WidgetKit surface — UITests can't drive the springboard — but the chrome matches the
/// home-screen widgets so the shot reads correctly in Frameit.
struct ScreenshotWidgetsGalleryView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.colorScheme) private var colorScheme
  @State private var isReady = false

  private let wallpaper = Color(red: 0.72, green: 0.74, blue: 0.82)

  var body: some View {
    ZStack {
      wallpaper.ignoresSafeArea()

      VStack(spacing: 16) {
        Spacer(minLength: 72)

        if let calories {
          largeCard(for: calories)
        }

        HStack(spacing: 16) {
          if let protein {
            smallCard(for: protein)
          }
          if let money {
            smallCard(for: money)
          }
        }

        Spacer(minLength: 120)
      }
      .padding(.horizontal, 28)
    }
    .accessibilityIdentifier(isReady ? "screenshot-ready" : "screenshot-pending")
    .task {
      // Let seed settle, then mark ready for Snapshot.
      try? await Task.sleep(for: .milliseconds(500))
      isReady = true
    }
  }

  // MARK: - Counters

  private var calories: CustomCounter? {
    counter(id: ScreenshotDataSeeder.caloriesID)
  }

  private var protein: CustomCounter? {
    counter(id: ScreenshotDataSeeder.proteinID)
  }

  private var money: CustomCounter? {
    counter(id: ScreenshotDataSeeder.moneyID)
  }

  private func counter(id: UUID) -> CustomCounter? {
    var descriptor = FetchDescriptor<CustomCounter>(
      predicate: #Predicate { $0.id == id }
    )
    descriptor.fetchLimit = 1
    return try? modelContext.fetch(descriptor).first
  }

  // MARK: - Cards

  private func largeCard(for counter: CustomCounter) -> some View {
    let model = CardModel(counter: counter, colorScheme: colorScheme)
    return cardChrome(colors: model.colors, cornerRadius: 24) {
      VStack(alignment: .leading, spacing: 0) {
        HStack(alignment: .top, spacing: 12) {
          VStack(alignment: .leading, spacing: 0) {
            Text("\(model.heroValue) \(counter.name)")
              .font(AppAppearancePreference.fontPack.font(size: 23, weight: .semibold))
              .tracking(-0.46)
              .foregroundStyle(model.colors.foreground)
              .lineLimit(1)
              .minimumScaleFactor(0.7)

            Text(model.subtitle)
              .font(AppAppearancePreference.fontPack.font(size: 16, weight: .semibold))
              .tracking(-0.32)
              .foregroundStyle(model.colors.foreground)
              .lineLimit(1)
          }
          .frame(maxWidth: .infinity, alignment: .leading)

          if let progress = model.progress {
            GoalProgressRing(
              progress: progress,
              size: 48,
              ringWidthOverride: model.ringWidth,
              ringGlowOverride: model.ringGlow,
              trackColor: model.colors.ringTrack,
              fillColor: model.colors.foreground
            )
          }
        }

        quickAddGrid(values: model.buttonValues, colors: model.colors)
          .padding(.top, 12)

        Spacer(minLength: 12)

        if !model.recent.isEmpty {
          recentList(entries: model.recent, colors: model.colors)
        }
      }
      .padding(16)
    }
    .frame(height: 382)
  }

  private func smallCard(for counter: CustomCounter) -> some View {
    let model = CardModel(counter: counter, colorScheme: colorScheme)
    return cardChrome(colors: model.colors, cornerRadius: 22) {
      VStack(alignment: .leading, spacing: 0) {
        if let progress = model.progress {
          GoalProgressRing(
            progress: progress,
            size: 48,
            ringWidthOverride: model.ringWidth,
            ringGlowOverride: model.ringGlow,
            trackColor: model.colors.ringTrack,
            fillColor: model.colors.foreground
          )
          .padding(.bottom, 12)
        }

        Text(counter.name)
          .font(AppAppearancePreference.fontPack.font(size: 18, weight: .semibold))
          .tracking(-0.36)
          .foregroundStyle(model.colors.foreground)
          .lineLimit(1)
          .minimumScaleFactor(0.7)

        Text(model.heroValue)
          .font(AppAppearancePreference.fontPack.font(size: 40, weight: .semibold))
          .tracking(-0.8)
          .foregroundStyle(model.colors.foreground)
          .lineLimit(1)
          .minimumScaleFactor(0.6)
          .padding(.top, -4)

        Text(model.subtitle)
          .font(AppAppearancePreference.fontPack.font(size: 14, weight: .semibold))
          .tracking(-0.28)
          .foregroundStyle(model.colors.foreground)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
          .padding(.top, -2)

        Spacer(minLength: 0)
      }
      .padding(16)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 170)
  }

  private func cardChrome(
    colors: WidgetThemeColors,
    cornerRadius: CGFloat,
    @ViewBuilder content: () -> some View
  ) -> some View {
    content()
      .background {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .fill(colors.backgroundStyle)
      }
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
  }

  private func quickAddGrid(values: [Double], colors: WidgetThemeColors) -> some View {
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
    return LazyVGrid(columns: columns, spacing: 8) {
      ForEach(values.prefix(8), id: \.self) { value in
        Text(CounterFormatting.amount(value))
          .font(AppAppearancePreference.fontPack.font(size: 15, weight: .semibold))
          .foregroundStyle(colors.buttonText)
          .frame(maxWidth: .infinity)
          .frame(height: 36)
          .background(
            colors.buttonFill,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
          )
      }
    }
  }

  private func recentList(
    entries: [(id: UUID, valueText: String, timestamp: Date)],
    colors: WidgetThemeColors
  ) -> some View {
    let format = Date.FormatStyle()
      .month(.abbreviated)
      .day(.twoDigits)
      .hour(.defaultDigits(amPM: .abbreviated))
      .minute(.twoDigits)

    return VStack(alignment: .leading, spacing: 0) {
      Rectangle()
        .fill(colors.foreground.opacity(0.40))
        .frame(height: 1)

      ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
        if index > 0 {
          Rectangle()
            .fill(colors.foreground.opacity(0.40))
            .frame(height: 1)
        }

        HStack(spacing: 12) {
          Text(entry.valueText)
            .font(AppAppearancePreference.fontPack.font(size: 18, weight: .semibold))
            .tracking(-0.54)
            .foregroundStyle(colors.foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.8)

          Spacer(minLength: 0)

          Text(entry.timestamp, format: format)
            .font(AppAppearancePreference.fontPack.font(size: 16, weight: .regular))
            .tracking(-0.32)
            .foregroundStyle(colors.foreground)
            .lineLimit(1)

          Image(systemName: "xmark")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(colors.foreground.opacity(0.55))
        }
        .frame(height: 40)
      }
    }
  }
}

// MARK: - Card model

private struct CardModel {
  let colors: WidgetThemeColors
  let heroValue: String
  let subtitle: String
  let progress: GoalProgress?
  let buttonValues: [Double]
  let recent: [(id: UUID, valueText: String, timestamp: Date)]
  let ringWidth: ProgressRingWidth?
  let ringGlow: Bool?

  init(counter: CustomCounter, colorScheme: ColorScheme) {
    let paletteIndex = AppAppearancePreference.resolvedPaletteIndex(counter.effectivePaletteIndex)
    colors = WidgetThemeColors(paletteIndex: paletteIndex, colorScheme: colorScheme)

    let total = counter.currentTotal()
    let progress = counter.currentProgress()
    self.progress = progress
    heroValue = progress?.heroValue ?? CounterFormatting.amount(total)
    subtitle = progress?.heroSubtitle.capitalized
      ?? counter.resetPeriod.periodCaption.capitalized

    let presets = QuickAddConfiguration.filledPresets(
      from: counter.presetAmounts,
      defaults: QuickAddConfiguration.defaultPresets(forCounterNamed: counter.name)
    )
    var seen = Set<Double>()
    var values: [Double] = []
    for value in presets where values.count < 8 {
      guard seen.insert(value).inserted else { continue }
      values.append(value)
    }
    buttonValues = values

    recent = CounterPeriodCalculator.currentEntries(for: counter)
      .prefix(4)
      .map { entry in
        (
          id: entry.id,
          valueText: CounterFormatting.amount(entry.amount),
          timestamp: entry.timestamp
        )
      }

    ringWidth = counter.overrideProgressRingWidth
    ringGlow = counter.overrideProgressRingGlow
  }
}
