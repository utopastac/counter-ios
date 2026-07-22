import SwiftData
import SwiftUI

/// Two-step fresh-install experience: pick a colour pack, then choose starter counters.
struct FreshInstallOnboardingView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @AppStorage(AppAppearancePreference.darkModeEnabledKey) private var isDarkModeEnabled = false
  @AppStorage(FreshInstallOnboarding.previewActiveKey) private var isPreviewActive = false

  @State private var step: Step = .colorPack
  @State private var selectedPack: CounterColorPack = AppAppearancePreference.colorPack
  @State private var drafts = FreshInstallOnboarding.defaultDrafts()
  @State private var editingTemplate: CounterTemplate?

  private enum Step: Hashable {
    case colorPack
    case counters

    var title: String {
      switch self {
      case .colorPack: "Select a color pack"
      case .counters: "Your starter counters"
      }
    }

    var progress: GoalProgress {
      switch self {
      case .colorPack: OnboardingToken.stepOneProgress
      case .counters: OnboardingToken.stepTwoProgress
      }
    }

    var accessibilityProgressValue: String {
      switch self {
      case .colorPack: "Step 1 of 2"
      case .counters: "Step 2 of 2"
      }
    }
  }

  private var colors: SemanticColors {
    SemanticColors.forColorScheme(isDarkModeEnabled ? .dark : .light)
  }

  private var colorScheme: ColorScheme {
    isDarkModeEnabled ? .dark : .light
  }

  private var canContinueFromCounters: Bool {
    drafts.contains(where: \.isSelected)
  }

  private var stepAnimation: Animation {
    MotionToken.settle(reduceMotion: reduceMotion)
  }

  private var colorPackColumns: [GridItem] {
    [
      GridItem(.flexible(), spacing: OnboardingToken.optionGap),
      GridItem(.flexible(), spacing: OnboardingToken.optionGap),
    ]
  }

  private var swatchColumns: [GridItem] {
    Array(
      repeating: GridItem(.flexible(), spacing: OnboardingToken.swatchGap),
      count: 5
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      header

      ScrollView {
        stepContent
          .padding(.horizontal, SheetToken.horizontal)
          .padding(.top, SpaceToken.u2)
          .padding(.bottom, SpaceToken.u4)
      }

      footer
        .padding(.horizontal, SheetToken.horizontal)
        .padding(.top, SpaceToken.u2)
        .padding(.bottom, SpaceToken.u4)
    }
    .background(colors.surfacePrimary)
    .counterDesignSystemFromAppearancePreference()
    .preferredColorScheme(colorScheme)
    .animation(stepAnimation, value: step)
    .sheet(item: $editingTemplate) { template in
      starterSettingsSheet(for: template)
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: OnboardingToken.ringToTitle) {
      HStack(alignment: .center, spacing: SpaceToken.u2) {
        GoalProgressRing(
          progress: step.progress,
          size: OnboardingToken.progressRingSize,
          trackColor: colors.progressRingTrack,
          fillColor: colors.textPrimary
        )
        .accessibilityLabel("Setup progress")
        .accessibilityValue(step.accessibilityProgressValue)

        Spacer(minLength: 0)

        if step == .colorPack {
          skipButton
            .transition(.opacity)
        }
      }

      Text(step.title)
        .counterTextStyle(.pageTitle)
        .contentTransition(.opacity)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, SheetToken.horizontal)
    .padding(.top, SpaceToken.u5)
    .padding(.bottom, SpaceToken.u1)
  }

  private var skipButton: some View {
    Button(action: skip) {
      Text("Skip")
        .counterTextStyle(.button, color: .onInteractiveFill)
        .padding(.horizontal, SpaceToken.u2)
        .padding(.vertical, SpaceToken.u1)
        .background(
          colors.interactivePrimaryFill,
          in: RadiusToken.continuousButton
        )
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private var stepContent: some View {
    Group {
      switch step {
      case .colorPack:
        colorPackStep
      case .counters:
        countersStep
      }
    }
    .id(step)
    .transition(
      reduceMotion
        ? .opacity
        : .asymmetric(
          insertion: .opacity.combined(with: .offset(x: 12)),
          removal: .opacity.combined(with: .offset(x: -12))
        )
    )
  }

  private var colorPackStep: some View {
    LazyVGrid(columns: colorPackColumns, spacing: OnboardingToken.optionGap) {
      ForEach(CounterColorPack.allCases) { pack in
        colorPackCard(pack)
      }
    }
  }

  private func colorPackCard(_ pack: CounterColorPack) -> some View {
    let isSelected = selectedPack == pack

    return Button {
      selectedPack = pack
    } label: {
      VStack(alignment: .leading, spacing: OnboardingToken.titleToSwatches) {
        Text(pack.label)
          .counterTextStyle(.settingsRowLabel)

        LazyVGrid(columns: swatchColumns, spacing: OnboardingToken.swatchGap) {
          ForEach(Array(pack.entries.enumerated()), id: \.offset) { _, entry in
            RoundedRectangle(
              cornerRadius: SizeToken.onboardingSwatchCorner,
              style: .continuous
            )
            .fill(swatchColor(for: entry))
            .aspectRatio(1, contentMode: .fit)
          }
        }
      }
      .padding(OnboardingToken.cardPadding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(colors.surfaceSheet, in: OnboardingToken.cardShape)
      .overlay {
        OnboardingToken.cardShape
          .stroke(
            isSelected ? colors.textPrimary : colors.borderSubtle,
            lineWidth: isSelected
              ? BorderToken.selectionSelected
              : BorderToken.selectionUnselected
          )
      }
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  private var countersStep: some View {
    VStack(spacing: OnboardingToken.optionGap) {
      ForEach($drafts) { $draft in
        starterCounterCard(draft: $draft)
      }
    }
  }

  private func starterCounterCard(draft: Binding<FreshInstallStarterDraft>) -> some View {
    let value = draft.wrappedValue
    let fill = packSwatchColor(at: value.paletteIndex)
    let title = value.name.isEmpty ? value.template.label : value.name

    return HStack(alignment: .center, spacing: SpaceToken.u2) {
      VStack(alignment: .leading, spacing: OnboardingToken.titleToSubtitle) {
        Text(title)
          .counterTextStyle(.listCardTitle)
          .opacity(value.isSelected ? 1 : OpacityToken.unselectedLabel)

        Text(value.subtitle)
          .counterTextStyle(.listCardCaption)
          .opacity(value.isSelected ? 1 : OpacityToken.unselectedLabel)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      SelectionControlIndicator(kind: .checkbox, isSelected: value.isSelected)
    }
    .padding(OnboardingToken.cardPadding)
    .background(
      value.isSelected ? fill : colors.surfaceSheet,
      in: OnboardingToken.counterCardShape
    )
    .overlay {
      if !value.isSelected {
        OnboardingToken.counterCardShape
          .stroke(colors.borderSubtle, lineWidth: BorderToken.selectionUnselected)
      }
    }
    .contentShape(OnboardingToken.counterCardShape)
    .onTapGesture {
      draft.wrappedValue.isSelected.toggle()
    }
    .onForcePress {
      AppHaptics.impact()
      openSettings(for: value.template)
    }
    .accessibilityAddTraits(value.isSelected ? .isSelected : [])
    .accessibilityLabel(title)
    .accessibilityValue(value.isSelected ? "Selected" : "Not selected")
    .accessibilityHint(value.subtitle)
    .accessibilityAction(named: "Edit") {
      openSettings(for: value.template)
    }
  }

  @ViewBuilder
  private func starterSettingsSheet(for template: CounterTemplate) -> some View {
    if let index = drafts.firstIndex(where: { $0.template == template }) {
      let draft = drafts[index]
      CounterSettingsView(
        values: draft.buttonValues,
        name: draft.name,
        unit: draft.unit,
        goalText: draft.goalText,
        resetPeriod: draft.resetPeriod,
        resetAnchorDay: draft.resetAnchorDay,
        goalDirection: draft.goalDirection,
        paletteIndex: draft.paletteIndex,
        defaultPresets: draft.template.defaultPresets,
        onSave: { save in
          applySettings(save, to: template)
        },
        onPaletteChange: { paletteIndex in
          if let index = drafts.firstIndex(where: { $0.template == template }) {
            drafts[index].paletteIndex = paletteIndex
          }
        }
      )
    }
  }

  private var footer: some View {
    VStack(spacing: SpaceToken.u2) {
      switch step {
      case .colorPack:
        PrimaryCapsuleButton(title: "Continue", isEnabled: true) {
          goToCounters()
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
      case .counters:
        PrimaryCapsuleButton(
          title: "Get started",
          isEnabled: canContinueFromCounters
        ) {
          finish(applySelection: true)
        }

        SecondaryCapsuleButton(title: "Back") {
          goToColorPack()
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
      }
    }
  }

  private func goToCounters() {
    applySelectedPack()
    withAnimation(stepAnimation) {
      step = .counters
    }
  }

  private func goToColorPack() {
    editingTemplate = nil
    withAnimation(stepAnimation) {
      step = .colorPack
    }
  }

  private func openSettings(for template: CounterTemplate) {
    applySelectedPack()
    editingTemplate = template
  }

  private func applySettings(_ save: CounterSettingsSave, to template: CounterTemplate) {
    guard let index = drafts.firstIndex(where: { $0.template == template }) else { return }
    if let name = save.name {
      drafts[index].name = name
    }
    drafts[index].unit = save.unit
    drafts[index].goalText = save.goal.map(CounterFormatting.editingText(for:)) ?? ""
    drafts[index].resetPeriod = save.resetPeriod
    drafts[index].resetAnchorDay = save.resetAnchorDay
    drafts[index].goalDirection = save.goalDirection
    drafts[index].buttonValues = save.buttonValues
    if let paletteIndex = save.paletteIndex {
      drafts[index].paletteIndex = paletteIndex
    }
    drafts[index].isSelected = true
  }

  private func applySelectedPack() {
    AppAppearancePreference.sharedDefaults.set(
      selectedPack.rawValue,
      forKey: AppAppearancePreference.colorPackKey
    )
  }

  private func swatchColor(for entry: CounterPaletteColorData) -> Color {
    let rgb = colorScheme == .dark ? entry.darkRGB : entry.lightRGB
    return Color(red: rgb.red, green: rgb.green, blue: rgb.blue)
  }

  /// Colour for a starter card from the pack chosen in step 1 (not the saved preference).
  private func packSwatchColor(at index: Int) -> Color {
    let entries = selectedPack.entries
    let normalized = ((index % entries.count) + entries.count) % entries.count
    return swatchColor(for: entries[normalized])
  }

  private func skip() {
    if isPreviewActive {
      FreshInstallOnboarding.endPreview()
      return
    }

    drafts = FreshInstallOnboarding.defaultDrafts()
    finish(applySelection: true)
  }

  private func finish(applySelection: Bool) {
    editingTemplate = nil

    if isPreviewActive {
      if applySelection {
        applySelectedPack()
        WidgetSnapshot.reloadTimelines()
      }
      FreshInstallOnboarding.endPreview()
      return
    }

    AppDataReset.finishFreshInstall(
      drafts: drafts,
      colorPack: selectedPack,
      in: modelContext
    )
  }
}

#Preview {
  PreviewModel.appRoot {
    FreshInstallOnboardingView()
  }
}
