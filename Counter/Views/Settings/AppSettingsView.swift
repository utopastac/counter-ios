import SwiftData
import SwiftUI

struct AppSettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @AppStorage(AppAppearancePreference.darkModeEnabledKey) private var isDarkModeEnabled = false
  @State private var showResetConfirmation = false

  private var colors: SemanticColors {
    SemanticColors.forColorScheme(isDarkModeEnabled ? .dark : .light)
  }

  var body: some View {
    VStack(spacing: 0) {
      CounterSheetHeader(
        title: "Settings",
        onDone: { dismiss() }
      )

      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          SettingsToggleRow(label: "Dark mode", isOn: $isDarkModeEnabled)

          SettingsDivider()

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
    .alert("Reset all data?", isPresented: $showResetConfirmation) {
      Button("Reset", role: .destructive) {
        AppDataReset.resetAll(in: modelContext)
        dismiss()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This will permanently delete all counters and entries. This can't be undone.")
    }
  }
}

#Preview {
  AppSettingsView()
}
