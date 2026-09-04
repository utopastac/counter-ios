import SwiftUI

/// Shared value + date row used by history lists and entry logs.
struct CounterValueDateRow<Trailing: View>: View {
  private let leading: AnyView
  let date: Date
  let dateFormat: Date.FormatStyle
  @ViewBuilder var trailing: () -> Trailing
  var onTap: (() -> Void)?

  init(
    valueText: String,
    date: Date,
    dateFormat: Date.FormatStyle,
    @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() },
    onTap: (() -> Void)? = nil
  ) {
    leading = AnyView(
      Text(valueText)
        .counterTextStyle(.historyListValue)
    )
    self.date = date
    self.dateFormat = dateFormat
    self.trailing = trailing
    self.onTap = onTap
  }

  init<Leading: View>(
    @ViewBuilder leading: @escaping () -> Leading,
    date: Date,
    dateFormat: Date.FormatStyle,
    @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() },
    onTap: (() -> Void)? = nil
  ) {
    self.leading = AnyView(leading())
    self.date = date
    self.dateFormat = dateFormat
    self.trailing = trailing
    self.onTap = onTap
  }

  var body: some View {
    let content = HStack(alignment: .center, spacing: SpaceToken.x3) {
      leading

      Spacer(minLength: 0)

      Text(date, format: dateFormat)
        .counterTextStyle(.historyListDate, color: .secondary)

      trailing()
    }
    .frame(height: HistoryToken.listRowHeight)
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())

    if let onTap {
      Button(action: onTap) {
        content
      }
      .buttonStyle(.plain)
    } else {
      content
    }
  }
}

#Preview {
  VStack(spacing: 0) {
    SettingsDivider()

    CounterValueDateRow(
      valueText: "24.5",
      date: .now,
      dateFormat: .dateTime.hour().minute()
    )

    SettingsDivider()

    CounterValueDateRow(
      valueText: "8",
      date: Calendar.current.date(byAdding: .day, value: -1, to: .now)!,
      dateFormat: .dateTime.weekday(.abbreviated).month(.abbreviated).day(.twoDigits)
    )
  }
  .padding()
  .counterDesignSystem(CounterDesignSystem(colorScheme: .light, accent: nil))
}
