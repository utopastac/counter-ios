import SwiftUI

/// Single-select (radio) vs multi-select (checkbox) indicator paired with a bordered row.
enum SelectionControlKind {
  case radio
  case checkbox
}

/// Bordered selection card: content on the left, radio/checkbox control on the right.
struct SelectionControlRow<Content: View>: View {
  @Environment(\.semanticColors) private var colors

  let kind: SelectionControlKind
  let isSelected: Bool
  let action: () -> Void
  @ViewBuilder let content: () -> Content

  var body: some View {
    Button(action: action) {
      HStack(spacing: SpaceToken.u2) {
        content()
          .frame(maxWidth: .infinity, alignment: .leading)

        SelectionControlIndicator(kind: kind, isSelected: isSelected)
      }
      .padding(.horizontal, SpaceToken.u2)
      .padding(.vertical, SpaceToken.u2)
      .frame(minHeight: SizeToken.quickAddHeight)
      .background(.clear, in: OnboardingToken.cardShape)
      .overlay {
        OnboardingToken.cardShape
          .stroke(
            isSelected ? colors.textPrimary : colors.borderSubtle,
            lineWidth: isSelected
              ? BorderToken.selectionSelected
              : BorderToken.selectionUnselected
          )
      }
      .contentShape(OnboardingToken.cardShape)
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}

struct SelectionControlIndicator: View {
  @Environment(\.semanticColors) private var colors

  let kind: SelectionControlKind
  let isSelected: Bool

  var body: some View {
    ZStack {
      switch kind {
      case .radio:
        radioIndicator
      case .checkbox:
        checkboxIndicator
      }
    }
    .frame(width: SizeToken.selectionControl, height: SizeToken.selectionControl)
  }

  @ViewBuilder
  private var radioIndicator: some View {
    if isSelected {
      RoundedRectangle(cornerRadius: SizeToken.selectionCheckboxCorner, style: .continuous)
        .fill(colors.textPrimary)
        .frame(
          width: SizeToken.selectionRadioFill,
          height: SizeToken.selectionRadioFill
        )
    } else {
      Circle()
        .stroke(colors.borderSubtle, lineWidth: BorderToken.selectionUnselected)
    }
  }

  private var checkboxIndicator: some View {
    ZStack {
      RoundedRectangle(cornerRadius: SizeToken.selectionCheckboxCorner, style: .continuous)
        .fill(isSelected ? colors.textPrimary : .clear)
        .overlay {
          RoundedRectangle(cornerRadius: SizeToken.selectionCheckboxCorner, style: .continuous)
            .stroke(
              isSelected ? colors.textPrimary : colors.borderSubtle,
              lineWidth: BorderToken.selectionUnselected
            )
        }

      if isSelected {
        Image(systemName: "checkmark")
          .font(.system(size: 12, weight: .bold))
          .foregroundStyle(colors.interactivePrimaryForeground)
      }
    }
  }
}

#Preview("Radio / Checkbox") {
  VStack(spacing: SpaceToken.u3) {
    SelectionControlRow(kind: .radio, isSelected: false, action: {}) {
      Text("Muted")
        .counterTextStyle(.settingsRowLabel)
    }
    SelectionControlRow(kind: .radio, isSelected: true, action: {}) {
      Text("Ocean")
        .counterTextStyle(.settingsRowLabel)
    }
    SelectionControlRow(kind: .checkbox, isSelected: false, action: {}) {
      Text("Protein")
        .counterTextStyle(.settingsRowLabel)
    }
    SelectionControlRow(kind: .checkbox, isSelected: true, action: {}) {
      Text("Calories")
        .counterTextStyle(.settingsRowLabel)
    }
  }
  .padding()
  .background(SemanticColors.light.surfacePrimary)
  .counterDesignSystem(CounterDesignSystem(colorScheme: .light, accent: nil))
}
