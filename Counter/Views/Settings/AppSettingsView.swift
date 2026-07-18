import SwiftData
import SwiftUI

struct AppSettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
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
    AppAppearancePreference.quickAddBatchWindowKey,
    store: AppAppearancePreference.sharedDefaults
  ) private var batchWindowSeconds = AppAppearancePreference.defaultBatchWindowSeconds
  @AppStorage(AppAppearancePreference.fpsCounterEnabledKey) private var isFPSCounterEnabled = false
  @State private var showResetConfirmation = false

  private var colors: SemanticColors {
    SemanticColors.forColorScheme(isDarkModeEnabled ? .dark : .light)
  }

  private var defaultResetPeriod: Binding<CounterResetPeriod> {
    Binding(
      get: { CounterResetPeriod(rawValue: defaultResetPeriodRaw) ?? .daily },
      set: { defaultResetPeriodRaw = $0.rawValue }
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
        VStack(alignment: .leading, spacing: 0) {
          SettingsToggleRow(icon: .moon, label: "Dark mode", isOn: $isDarkModeEnabled)
          SettingsToggleRow(icon: .vibrate, label: "Haptics", isOn: $isHapticsEnabled)
          SettingsToggleRow(icon: .rows3, label: "Compact mode", isOn: $isCompactModeEnabled)

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

          SettingsToggleRow(icon: .palette, label: "Mono", isOn: $isMonoEnabled)

          if isMonoEnabled {
            SettingsSectionHeader(title: "Colour")
              .padding(.top, SpaceToken.u1)

            SettingsColorSwatchGrid(selection: $monoPaletteIndex)
          }

          SettingsSectionDivider()

          SettingsSectionHeader(title: "Debug")

          SettingsToggleRow(icon: .chartBar, label: "FPS counter", isOn: $isFPSCounterEnabled)
          SettingsStaticRow(icon: .info, label: "Version", value: appVersionText)

          SettingsSectionDivider()

          SettingsDestructiveRow(label: "Reset all data") {
            showResetConfirmation = true
          }
        }
        .padding(.horizontal, SheetToken.horizontal)
        .padding(.top, SpaceToken.u1)
        .padding(.bottom, SpaceToken.u4)
      }
    }
    .background(colors.surfaceSheet)
    .counterDesignSystemFromAppearancePreference()
    .counterSheetPresentation()
    .onChange(of: isMonoEnabled) { _, _ in
      WidgetSnapshot.reloadTimelines()
    }
    .onChange(of: monoPaletteIndex) { _, _ in
      WidgetSnapshot.reloadTimelines()
    }
    .alert("Reset all data?", isPresented: $showResetConfirmation) {
      Button("Reset", role: .destructive) {
        AppDataReset.resetAll(in: modelContext)
        dismiss()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This will permanently delete everything. This can't be undone.")
    }
  }
}

#Preview {
  AppSettingsView()
}
