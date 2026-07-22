import Charts
import SwiftUI

/// Horizontally paged history chart (Apple Health–style).
/// Pages are ordered oldest → newest left to right, so swiping right goes further back.
struct HistoryBarChart: View {
  @Environment(\.semanticColors) private var colors
  @Environment(\.counterAccent) private var accent
  @Environment(\.colorScheme) private var colorScheme

  let period: HistoryPeriod
  @Binding var windowOffset: Int
  let maxWindowOffset: Int
  let dataForOffset: (Int) -> [DailyValue]
  var onSelectBar: ((DailyValue) -> Void)?

  private var scrollPosition: Binding<Int?> {
    Binding(
      get: { windowOffset },
      set: { newValue in
        if let newValue {
          windowOffset = min(max(0, newValue), maxWindowOffset)
        }
      }
    )
  }

  /// Counter's chosen colour when themed; otherwise the default muted surface.
  private var chartBackground: AnyShapeStyle {
    if let accent {
      return accent.palette.backgroundStyle(for: colorScheme)
    }
    return AnyShapeStyle(ComponentColor.historyChartBackground(colors))
  }

  /// Opposite-scheme palette colour for contrast on the chosen background.
  private var barFill: Color {
    accent?.palette.inverseBackground(for: colorScheme)
      ?? ComponentColor.historyChartBarFill(colors)
  }

  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack(spacing: 0) {
        ForEach(Array((0...maxWindowOffset).reversed()), id: \.self) { offset in
          chartPage(data: dataForOffset(offset))
            .containerRelativeFrame(.horizontal)
            .id(offset)
        }
      }
      .scrollTargetLayout()
    }
    .scrollTargetBehavior(.paging)
    .scrollPosition(id: scrollPosition)
    .scrollIndicators(.hidden)
    .defaultScrollAnchor(.trailing)
    .frame(height: HistoryToken.chartHeight)
    .padding(HistoryToken.chartPadding)
    .background(
      chartBackground,
      in: RoundedRectangle(cornerRadius: HistoryToken.chartCornerRadius, style: .continuous)
    )
  }

  @ViewBuilder
  private func chartPage(data: [DailyValue]) -> some View {
    if data.isEmpty {
      emptyState
    } else {
      chart(data: data)
    }
  }

  private var emptyState: some View {
    VStack(spacing: SpaceToken.u1) {
      CounterLucideIcon(icon: .chartBar, color: colors.textSecondary)
      Text("No data")
        .counterTextStyle(.historyChartAxis, color: .historyChartAxis, compact: true)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func chart(data: [DailyValue]) -> some View {
    let yAxisMaximum = HistoryChartScale.niceMaximum(for: data.map(\.value))
    let yAxisValues = HistoryChartScale.tickValues(maximum: yAxisMaximum)

    return Chart(data) { item in
      BarMark(
        x: .value("Date", item.date, unit: xAxisUnit),
        y: .value("Value", item.value),
        width: .ratio(0.55)
      )
      .foregroundStyle(barFill)
      .cornerRadius(HistoryToken.chartBarCornerRadius)
    }
    .chartYScale(domain: 0...yAxisMaximum)
    .chartYAxis {
      AxisMarks(position: .trailing, values: yAxisValues) { value in
        AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
          .foregroundStyle(ComponentColor.historyChartGridLine(colors))
        AxisValueLabel(anchor: .topLeading, collisionResolution: .disabled) {
          if let tick = value.as(Double.self) {
            Text(HistoryChartScale.formattedTick(tick))
              .counterTextStyle(.historyChartAxis, color: .historyChartAxis, compact: true)
          }
        }
      }
    }
    .chartXAxis {
      if period == .daily {
        AxisMarks(values: xAxisValues(for: data)) { value in
          AxisValueLabel(centered: true, collisionResolution: .disabled) {
            if let date = value.as(Date.self) {
              Text(date, format: xLabelFormat)
                .counterTextStyle(.historyChartAxis, color: .historyChartAxis, compact: true)
            }
          }
        }
      } else {
        AxisMarks(values: .automatic) { value in
          AxisValueLabel(centered: true, collisionResolution: .disabled) {
            if let date = value.as(Date.self) {
              Text(date, format: xLabelFormat)
                .counterTextStyle(.historyChartAxis, color: .historyChartAxis, compact: true)
            }
          }
        }
      }
    }
    .chartPlotStyle { plotArea in
      plotArea
        .padding(.trailing, SpaceToken.u1)
        .padding(.bottom, SpaceToken.x1)
    }
    .chartOverlay { proxy in
      GeometryReader { geometry in
        Rectangle()
          .fill(.clear)
          .contentShape(Rectangle())
          .onTapGesture { location in
            guard let onSelectBar,
                  let plotFrameAnchor = proxy.plotFrame else { return }
            let plotFrame = geometry[plotFrameAnchor]
            let xPosition = location.x - plotFrame.origin.x
            guard plotFrame.width > 0,
                  let date: Date = proxy.value(atX: xPosition, as: Date.self) else { return }
            if let item = nearestItem(in: data, to: date) {
              onSelectBar(item)
            }
          }
      }
    }
  }

  private func nearestItem(in data: [DailyValue], to date: Date) -> DailyValue? {
    data.min { lhs, rhs in
      abs(lhs.date.timeIntervalSince(date)) < abs(rhs.date.timeIntervalSince(date))
    }
  }

  private var xAxisUnit: Calendar.Component {
    switch period {
    case .daily: .hour
    case .monthly: .day
    case .weekly: .weekOfYear
    }
  }

  private var xLabelFormat: Date.FormatStyle {
    switch period {
    case .daily:
      return .dateTime.hour(.defaultDigits(amPM: .abbreviated))
    case .monthly, .weekly:
      return .dateTime.day().month(.abbreviated)
    }
  }

  private func xAxisValues(for data: [DailyValue]) -> [Date] {
    // Sparse hour labels like Health: midnight, 6, noon, 6pm.
    let hours: Set<Int> = [0, 6, 12, 18]
    return data.filter { hours.contains(Calendar.current.component(.hour, from: $0.date)) }.map(\.date)
  }
}

#Preview {
  struct PreviewHost: View {
    @State private var offset = 0

    var body: some View {
      HistoryBarChart(
        period: .daily,
        windowOffset: $offset,
        maxWindowOffset: 2,
        dataForOffset: { page in
          let calendar = Calendar.current
          let day = calendar.date(byAdding: .day, value: -page, to: .now) ?? .now
          let start = calendar.startOfDay(for: day)
          return (0..<24).compactMap { hour in
            guard let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: start) else {
              return nil
            }
            return DailyValue(date: date, value: Double((hour + page) % 5 * 100))
          }
        }
      )
      .padding()
      .counterAccent(.calories)
      .counterDesignSystem(CounterDesignSystem(colorScheme: .light, accent: .calories))
    }
  }

  return PreviewHost()
}
