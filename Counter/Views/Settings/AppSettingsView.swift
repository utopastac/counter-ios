import SwiftData
import SwiftUI

struct AppSettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \CustomCounter.sortOrder) private var counters: [CustomCounter]
  @AppStorage(AppAppearancePreference.darkModeEnabledKey) private var isDarkModeEnabled = false
  @AppStorage(AppAppearancePreference.hapticsEnabledKey) private var isHapticsEnabled = true
  @AppStorage(AppAppearancePreference.compactModeEnabledKey) private var isCompactModeEnabled = false
  @AppStorage(AppAppearancePreference.defaultResetPeriodKey) private var defaultResetPeriodRaw =
    CounterResetPeriod.daily.rawValue
  @AppStorage(
    AppAppearancePreference.monoEnabledKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var isMonoEnabled = false
  @AppStorage(
    AppAppearancePreference.monoPaletteIndexKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var monoPaletteIndex = 0
  @AppStorage(
    AppAppearancePreference.tintEnabledKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var isTintEnabled = true
  @AppStorage(
    AppAppearancePreference.colorPackKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var colorPackRaw = CounterColorPack.muted.rawValue
  @AppStorage(
    AppAppearancePreference.progressRingWidthKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var progressRingWidthRaw = ProgressRingWidth.balanced.rawValue
  @AppStorage(
    AppAppearancePreference.quickAddBatchWindowKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var batchWindowSeconds = AppAppearancePreference.defaultBatchWindowSeconds
  @AppStorage(AppAppearancePreference.fpsCounterEnabledKey) private var isFPSCounterEnabled = false
  @State private var showResetConfirmation = false
  @State private var showColorPackPicker = false
  @State private var exportURL: URL?

  private var colors: SemanticColors {
    SemanticColors.forColorScheme(isDarkModeEnabled ? .dark : .light)
  }

  private var defaultResetPeriod: Binding<CounterResetPeriod> {
    Binding(
      get: { CounterResetPeriod(rawValue: defaultResetPeriodRaw) ?? .daily },
      set: { defaultResetPeriodRaw = $0.rawValue }
    )
  }

  private var colorPack: Binding<CounterColorPack> {
    Binding(
      get: { CounterColorPack(rawValue: colorPackRaw) ?? .muted },
      set: { colorPackRaw = $0.rawValue }
    )
  }

  private var progressRingWidth: Binding<ProgressRingWidth> {
    Binding(
      get: { ProgressRingWidth(rawValue: progressRingWidthRaw) ?? .balanced },
      set: { progressRingWidthRaw = $0.rawValue }
    )
  }

  private var appVersionText: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    return "\(version) (\(build))"
  }

  var body: some View {
    VStack(spacing: 0) {
      CounterSheetHeader(
        title: "Settings",
        onDone: { dismiss() }
      )

      ScrollView {
        VStack(alignment: .leading, spacing: SettingsToken.sectionGap) {
          VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(title: "General")
            SettingsToggleRow(icon: .vibrate, label: "Haptics", isOn: $isHapticsEnabled)
            SettingsPickerRow(
              icon: .calendar,
              label: "Default reset",
              selection: defaultResetPeriod,
              options: CounterResetPeriod.allCases.map { ($0, $0.label) }
            )
            SettingsPickerRow(
              icon: .timer,
              label: "Batch window",
              selection: $batchWindowSeconds,
              options: AppAppearancePreference.batchWindowOptions.map {
                ($0, AppAppearancePreference.batchWindowLabel(for: $0))
              }
            )
          }

          VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(title: "Theme")
            SettingsToggleRow(icon: .rows3, label: "Compact", isOn: $isCompactModeEnabled)
            SettingsToggleRow(icon: .moon, label: "Dark mode", isOn: $isDarkModeEnabled)
            SettingsPickerRow(
              icon: .ringDot,
              label: "Ring width",
              selection: progressRingWidth,
              options: ProgressRingWidth.allCases.map { ($0, $0.label) }
            )
            SettingsDisclosureRow(
              icon: .palette,
              label: "Colour pack",
              value: colorPack.wrappedValue.label
            ) {
              showColorPackPicker = true
            }
            SettingsToggleRow(icon: .blend, label: "Tint", isOn: $isTintEnabled)
            SettingsToggleRow(icon: .paintBucket, label: "Mono", isOn: $isMonoEnabled)
          }

          if isMonoEnabled {
            VStack(alignment: .leading, spacing: 0) {
              SettingsSectionHeader(title: "Color")
              SettingsColorSwatchGrid(selection: $monoPaletteIndex)
            }
          }

          VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(title: "Data")
            if let exportURL {
              ShareLink(item: exportURL) {
                SettingsStaticRow(icon: .logs, label: "Export CSV", value: "Export")
              }
            }
          }

          VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(title: "Development")
            SettingsToggleRow(icon: .chartBar, label: "FPS counter", isOn: $isFPSCounterEnabled)
            SettingsActionRow(icon: .listRestart, label: "Preview fresh install") {
              dismiss()
              Task { @MainActor in
                await Task.yield()
                FreshInstallOnboarding.requestPreview()
              }
            }
            SettingsStaticRow(icon: .info, label: "Version", value: appVersionText)
          }

          VStack(alignment: .leading, spacing: 0) {
            SettingsDivider()
            SettingsDestructiveRow(label: "Reset all data") {
              showResetConfirmation = true
            }
          }
        }
        .padding(.horizontal, SheetToken.horizontal)
        .padding(.top, SpaceToken.u2)
        .padding(.bottom, SpaceToken.u4)
      }
    }
    .background(colors.surfaceSheet)
    .counterDesignSystemFromAppearancePreference()
    .counterSheetPresentation()
    .onAppear {
      prepareExportFile()
    }
    .onChange(of: counters.map(\.id)) { _, _ in
      prepareExportFile()
    }
    .onChange(of: isMonoEnabled) { _, _ in
      WidgetSnapshot.reloadTimelines()
    }
    .onChange(of: monoPaletteIndex) { _, _ in
      WidgetSnapshot.reloadTimelines()
    }
    .onChange(of: isTintEnabled) { _, _ in
      WidgetSnapshot.reloadTimelines()
    }
    .onChange(of: colorPackRaw) { _, _ in
      WidgetSnapshot.reloadTimelines()
    }
    .onChange(of: progressRingWidthRaw) { _, _ in
      WidgetSnapshot.reloadTimelines()
    }
    .sheet(isPresented: $showColorPackPicker) {
      ColorPackPickerView(selection: colorPack)
    }
    .alert("Reset all data?", isPresented: $showResetConfirmation) {
      Button("Reset", role: .destructive) {
        // Dismiss first so @Query teardown isn't racing the wipe on the same turn.
        dismiss()
        Task { @MainActor in
          await Task.yield()
          AppDataReset.resetAll(in: modelContext)
        }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This deletes your counters and walks you through choosing a colour pack and starter set.")
    }
  }

  private func prepareExportFile() {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(CounterExport.csvFilename())
    let data = CounterExport.csvData(counters: counters)
    try? data.write(to: url, options: .atomic)
    exportURL = url
  }
}

#Preview {
  AppSettingsView()
    .modelContainer(for: [CustomCounter.self, CounterEntry.self], inMemory: true)
}
