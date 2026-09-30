import SwiftUI

/// Shared value + date row used by history lists and entry logs.
struct CounterValueDateRow<Trailing: View>: View {
  private let leading: AnyView
  let date: Date
  let dateFormat: Date.FormatStyle
  let dateStyle: CounterTextStyle
  let rowHeight: CGFloat
  @ViewBuilder var trailing: () -> Trailing
  var onTap: (() -> Void)?

  init(
    valueText: String,
    date: Date,
    dateFormat: Date.FormatStyle,
    valueStyle: CounterTextStyle = .historyListValue,
    dateStyle: CounterTextStyle = .historyListDate,
    rowHeight: CGFloat = HistoryToken.listRowHeight,
    @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() },
    onTap: (() -> Void)? = nil
  ) {
    leading = AnyView(
      Text(valueText)
        .counterTextStyle(valueStyle)
    )
    self.date = date
    self.dateFormat = dateFormat
    self.dateStyle = dateStyle
    self.rowHeight = rowHeight
    self.trailing = trailing
    self.onTap = onTap
  }

  init<Leading: View>(
    @ViewBuilder leading: @escaping () -> Leading,
    date: Date,
    dateFormat: Date.FormatStyle,
    dateStyle: CounterTextStyle = .historyListDate,
    rowHeight: CGFloat = HistoryToken.listRowHeight,
    @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() },
    onTap: (() -> Void)? = nil
  ) {
    self.leading = AnyView(leading())
    self.date = date
    self.dateFormat = dateFormat
    self.dateStyle = dateStyle
    self.rowHeight = rowHeight
    self.trailing = trailing
    self.onTap = onTap
  }

  var body: some View {
    HStack(alignment: .center, spacing: SpaceToken.x3) {
      Group {
        if let onTap {
          Button(action: onTap) {
            mainContent
          }
          .buttonStyle(.plain)
        } else {
          mainContent
        }
      }

      // Keep trailing chrome (e.g. delete) outside the row tap target.
      trailing()
    }
    .frame(height: rowHeight)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var mainContent: some View {
    HStack(alignment: .center, spacing: SpaceToken.x3) {
      leading

      Spacer(minLength: 0)

      Text(date, format: dateFormat)
        .counterTextStyle(dateStyle, color: .secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
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
