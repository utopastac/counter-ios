import SwiftUI

private struct SheetHeightKey: PreferenceKey {
  static var defaultValue: CGFloat = 0

  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}

struct AmountEntrySheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.semanticColors) private var colors

  let title: String
  let subtitle: String?
  let headerIcon: CounterLucideIconName
  let actionTitle: String
  let initialText: String
  let onSubmit: (Int) -> Void

  @State private var amountText: String
  @State private var sheetHeight: CGFloat = 280
  @FocusState private var isAmountFocused: Bool

  private let maxDigits = 6

  init(
    title: String,
    subtitle: String? = nil,
    headerIcon: CounterLucideIconName = .chartBar,
    actionTitle: String,
    initialText: String = "",
    onSubmit: @escaping (Int) -> Void
  ) {
    self.title = title
    self.subtitle = subtitle
    self.headerIcon = headerIcon
    self.actionTitle = actionTitle
    self.initialText = initialText
    self.onSubmit = onSubmit
    _amountText = State(initialValue: initialText)
  }

  var body: some View {
    VStack(spacing: 0) {
      sheetHandle

      sheetHeader
        .padding(.horizontal, SheetToken.horizontal)
        .padding(.top, SheetToken.contentTop)

      amountInput
        .padding(.horizontal, SheetToken.horizontal)
        .padding(.top, SheetToken.amountTopSpacing)

      PrimaryCapsuleButton(title: actionTitle, isEnabled: parsedValue != nil) {
        guard let value = parsedValue else { return }
        onSubmit(value)
        dismiss()
      }
      .padding(.horizontal, SheetToken.horizontal)
      .padding(.top, SheetToken.actionTop)
      .padding(.bottom, SheetToken.contentBottom)
    }
    .background {
      GeometryReader { geometry in
        Color.clear.preference(key: SheetHeightKey.self, value: geometry.size.height)
      }
    }
    .onPreferenceChange(SheetHeightKey.self) { height in
      if height > 0 {
        sheetHeight = height
      }
    }
    .presentationDetents([.height(sheetHeight)])
    .presentationDragIndicator(.hidden)
    .presentationBackground {
      SheetToken.halfSheetTopCornerShape
        .fill(colors.surfaceSheet)
    }
    .onAppear {
      isAmountFocused = true
    }
    .onChange(of: amountText) { _, newValue in
      let filtered = String(newValue.filter(\.isWholeNumber).prefix(maxDigits))
      if filtered != newValue {
        amountText = filtered
      }
    }
  }

  private var amountInput: some View {
    ZStack {
      LargeAmountInput(text: amountText)

      TextField("", text: $amountText)
        .keyboardType(.numberPad)
        .focused($isAmountFocused)
        .opacity(0.02)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: SheetToken.amountInputHeight)
        .accessibilityLabel("Amount")
    }
  }

  private var sheetHeader: some View {
    VStack(alignment: .leading, spacing: SheetToken.headerSpacing) {
      HStack(spacing: SheetToken.headerIconSpacing) {
        CounterLucideIcon(icon: headerIcon, color: colors.textPrimary)
        Text(title)
          .counterTextStyle(.sheetTitle)
      }

      if let subtitle {
        Text(subtitle)
          .counterTextStyle(.sheetSubtitle, color: .secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var sheetHandle: some View {
    Capsule()
      .fill(colors.textTertiary)
      .frame(width: SheetToken.handleWidth, height: SheetToken.handleHeight)
      .padding(.top, SpaceToken.x2)
  }

  private var parsedValue: Int? {
    guard let value = Int(amountText.trimmingCharacters(in: .whitespaces)), value > 0 else {
      return nil
    }
    return value
  }
}

#Preview("Add") {
  Text("Preview")
    .sheet(isPresented: .constant(true)) {
      AmountEntrySheet(
        title: "Add amount",
        actionTitle: "Add"
      ) { _ in }
      .environment(\.counterAccent, nil)
      .counterDesignSystemFromColorScheme()
    }
}

#Preview("Edit") {
  Text("Preview")
    .sheet(isPresented: .constant(true)) {
      AmountEntrySheet(
        title: "Edit",
        actionTitle: "Save",
        initialText: "150"
      ) { _ in }
      .environment(\.counterAccent, nil)
      .counterDesignSystemFromColorScheme()
    }
}
