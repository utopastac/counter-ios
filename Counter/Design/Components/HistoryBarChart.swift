import Charts
import SwiftUI

enum HistoryChartScale {
  static let defaultMaximum: Double = 2500

  static func niceMaximum(for values: [Double]) -> Double {
    let maxValue = values.max() ?? 0
    guard maxValue > 0 else { return defaultMaximum }

    let padded = maxValue * 1.1
    let candidates: [Double] = [250, 500, 750, 1000, 1250, 1500, 2000, 2500, 3000, 5000, 10000]
    return candidates.first { $0 >= padded } ?? padded.rounded(.up)
  }

  static func tickValues(maximum: Double) -> [Double] {
    guard maximum > 0 else { return [0] }

    let step = maximum / 3
    return [0, step, step * 2, maximum]
  }

  static func formattedTick(_ value: Double) -> String {
    "\(Int(value.rounded()))"
  }
}

struct HistoryBarChart: View {
  @Environment(\.semanticColors) private var colors

  let data: [DailyValue]
  let period: HistoryPeriod

  private var yAxisMaximum: Double {
    HistoryChartScale.niceMaximum(for: data.map(\.value))
  }

  private var yAxisValues: [Double] {
    HistoryChartScale.tickValues(maximum: yAxisMaximum)
  }

  var body: some View {
    Group {
      if data.isEmpty {
        emptyState
      } else {
        chart
      }
    }
    .frame(height: HistoryToken.chartHeight)
    .padding(HistoryToken.chartPadding)
    .background(
      ComponentColor.historyChartBackground(colors),
      in: RoundedRectangle(cornerRadius: HistoryToken.chartCornerRadius, style: .continuous)
    )
  }

  private var emptyState: some View {
    VStack(spacing: SpaceToken.u1) {
      CounterLucideIcon(icon: .chartBar, color: colors.textSecondary)
      Text("No data")
        .counterTextStyle(.historyChartAxis, color: .historyChartAxis, compact: true)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var chart: some View {
    Chart(data) { item in
      BarMark(
        x: .value("Date", item.date, unit: xAxisUnit),
        y: .value("Value", item.value),
        width: .ratio(0.55)
      )
      .foregroundStyle(ComponentColor.historyChartBarFill(colors))
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
      AxisMarks(values: .automatic) { value in
        AxisValueLabel(centered: true, collisionResolution: .disabled) {
          if let date = value.as(Date.self) {
            Text(date, format: xLabelFormat)
              .counterTextStyle(.historyChartAxis, color: .historyChartAxis, compact: true)
          }
        }
      }
    }
    .chartPlotStyle { plotArea in
      plotArea
        .padding(.trailing, SpaceToken.u1)
        .padding(.bottom, SpaceToken.x1)
    }
  }

  private var xAxisUnit: Calendar.Component {
    switch period {
    case .daily, .monthly: .day
    case .weekly: .weekOfYear
    }
  }

  private var xLabelFormat: Date.FormatStyle {
    switch period {
    case .daily, .monthly, .weekly:
      return .dateTime.day().month(.abbreviated)
    }
  }
}

#Preview {
  HistoryBarChart(
    data: [
      DailyValue(date: Calendar.current.date(byAdding: .day, value: -6, to: .now)!, value: 900),
      DailyValue(date: Calendar.current.date(byAdding: .day, value: -4, to: .now)!, value: 1200),
      DailyValue(date: Calendar.current.date(byAdding: .day, value: -2, to: .now)!, value: 600),
      DailyValue(date: .now, value: 1800)
    ],
    period: .daily
  )
  .padding()
  .counterDesignSystem(CounterDesignSystem(colorScheme: .light, accent: nil))
}
