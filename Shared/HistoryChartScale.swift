import Foundation

/// Y-axis scaling for the history bar chart: picks a "nice" round maximum above the largest
/// value instead of scaling the axis to the data exactly (which would make the tallest bar
/// touch the top with no headroom, and would pick visually arbitrary tick values), and derives
/// evenly-spaced tick values from that maximum.
nonisolated enum HistoryChartScale {
  static let defaultMaximum: Double = 2500

  /// The smallest of a fixed set of round candidates that's still `>=` the data's max value
  /// plus 10% headroom, falling back to a plain rounded-up value beyond the largest candidate.
  static func niceMaximum(for values: [Double]) -> Double {
    let maxValue = values.max() ?? 0
    guard maxValue > 0 else { return defaultMaximum }

    let padded = maxValue * 1.1
    let candidates: [Double] = [250, 500, 750, 1000, 1250, 1500, 2000, 2500, 3000, 5000, 10000]
    return candidates.first { $0 >= padded } ?? padded.rounded(.up)
  }

  /// Four evenly-spaced ticks from `0` to `maximum` (0%, 33%, 67%, 100%).
  static func tickValues(maximum: Double) -> [Double] {
    guard maximum > 0 else { return [0] }

    let step = maximum / 3
    return [0, step, step * 2, maximum]
  }

  static func formattedTick(_ value: Double) -> String {
    "\(Int(value.rounded()))"
  }
}
