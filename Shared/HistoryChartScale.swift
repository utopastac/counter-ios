import Foundation

/// Y-axis scaling for the history bar chart.
///
/// When the counter has a target, the axis top is that target — or the next whole
/// multiple, once a bar passes it — and the grid lands on halves or multiples of it.
/// A notes target of 1 stays at 1. A calorie target of 2,200 stays at 2,200, not a
/// fixed ceiling split into thirds (833, 1,667, 2,500).
/// Counters with no target fall back to a 1-2-5 ceiling a little above the data.
nonisolated enum HistoryChartScale {
  /// Axis top when every bucket is zero and the counter has no target.
  static let defaultMaximum: Double = 4

  /// Axis top for `values`. Pass `target` (the counter's goal) so the scale is
  /// that goal, or the next multiple of it that still covers the tallest bar.
  static func niceMaximum(for values: [Double], target: Double? = nil) -> Double {
    if let target, target > 0 {
      return maximum(forTarget: target, maxValue: values.max() ?? 0)
    }
    return dataMaximum(for: values)
  }

  /// Evenly spaced ticks from 0 through `maximum`. With a `target`, each tick is
  /// a half or a whole multiple of that target.
  static func tickValues(maximum: Double, target: Double? = nil) -> [Double] {
    guard maximum > 0 else { return [0] }

    let step: Double
    if let target, target > 0 {
      step = targetStep(for: target, maximum: maximum)
    } else {
      step = niceStep(dividing: maximum)
    }
    let intervals = max(Int((maximum / step).rounded()), 1)
    return (0...intervals).map { index in
      snapped(Double(index) * step)
    }
  }

  /// Smallest whole multiple of `target` that is at least the target and covers `maxValue`.
  private static func maximum(forTarget target: Double, maxValue: Double) -> Double {
    let ratio = max(maxValue, 0) / target
    let multiplier = max(1, Int(ceil(ratio - 1e-8)))
    return snapped(Double(multiplier) * target)
  }

  /// Grid step measured from `target`: count by 1 for a small whole target, otherwise
  /// half a target (while the axis is a single target) or whole targets after that.
  private static func targetStep(for target: Double, maximum: Double) -> Double {
    let units = maximum / target
    let wholeTarget = abs(target.rounded() - target) < 1e-6

    if wholeTarget, target >= 1, target <= 6, maximum >= 1, maximum <= 6 {
      return 1
    }

    if units <= 1 + 1e-6 {
      let half = target / 2
      if wholeTarget, half < 1 {
        return target
      }
      return half
    }

    if units <= 6 + 1e-6 {
      return target
    }

    let multiplier = max(Int(units.rounded()), 1)
    return snapped(target * Double(targetFactor(dividing: multiplier)))
  }

  /// 1-2-5 factor of the target-multiplier that leaves a few gridlines.
  private static func targetFactor(dividing multiplier: Int) -> Int {
    guard multiplier > 1 else { return 1 }

    var best = 1
    var bestScore = Int.max
    var magnitude = 1
    while magnitude < multiplier {
      for nice in [1, 2, 5] {
        let factor = nice * magnitude
        guard factor < multiplier, multiplier.isMultiple(of: factor) else { continue }
        let intervals = multiplier / factor
        guard (2...5).contains(intervals) else { continue }
        let score = abs(intervals - 3)
        if score < bestScore || (score == bestScore && factor > best) {
          bestScore = score
          best = factor
        }
      }
      if magnitude > multiplier / 10 { break }
      magnitude *= 10
    }
    return best
  }

  /// Smallest 1-2-5 ceiling that still leaves about 10% headroom above the data.
  private static func dataMaximum(for values: [Double]) -> Double {
    let maxValue = values.max() ?? 0
    guard maxValue > 0 else { return defaultMaximum }

    let padded = maxValue * 1.1
    var step = niceStep(spanning: padded, intervals: 4)
    // Whole counts (a note, a workout) shouldn't grow half-step gridlines.
    if maxValue >= 1 {
      step = max(step, 1)
    }
    return ceiling(padded, step: step)
  }

  static func formattedTick(_ value: Double) -> String {
    CounterFormatting.amount(snappedToHundredths(value))
  }

  /// Rough step across `intervals`, snapped onto 1, 2, or 5 × 10^n.
  private static func niceStep(spanning span: Double, intervals: Int) -> Double {
    let rough = span / Double(max(intervals, 1))
    return niceNumber(rough)
  }

  private static func niceNumber(_ value: Double) -> Double {
    guard value.isFinite, value > 0 else { return 1 }

    let exponent = floor(log10(value))
    let magnitude = pow(10, exponent)
    let fraction = value / magnitude
    let niceFraction: Double
    if fraction <= 1 {
      niceFraction = 1
    } else if fraction <= 2 {
      niceFraction = 2
    } else if fraction <= 5 {
      niceFraction = 5
    } else {
      niceFraction = 10
    }
    return niceFraction * magnitude
  }

  /// A 1-2-5 step that divides `maximum` into a few intervals (about four ticks).
  private static func niceStep(dividing maximum: Double) -> Double {
    guard maximum.isFinite, maximum > 0 else { return 1 }

    let exponent = floor(log10(maximum))
    let wholeOnly = abs(maximum.rounded() - maximum) < 1e-6
    var bestStep = maximum
    var bestScore = Double.greatestFiniteMagnitude

    var magnitude = pow(10, exponent - 2)
    for _ in 0..<5 {
      for fraction in [1.0, 2.0, 5.0] {
        let step = fraction * magnitude
        guard step > 0, step <= maximum + 1e-8 else { continue }
        if wholeOnly, step < 1 { continue }

        let intervals = maximum / step
        let rounded = intervals.rounded()
        guard abs(intervals - rounded) < 1e-4 else { continue }

        let count = Int(rounded)
        guard (2...6).contains(count) else { continue }

        // Closest to three intervals wins. Ties keep the finer grid.
        let score = abs(Double(count) - 3) - Double(count) * 0.01
        if score < bestScore {
          bestScore = score
          bestStep = step
        }
      }
      magnitude *= 10
    }
    return bestStep
  }

  private static func ceiling(_ value: Double, step: Double) -> Double {
    let intervals = (value / step - 1e-8).rounded(.up)
    return snapped(max(intervals, 1) * step)
  }

  private static func snapped(_ value: Double) -> Double {
    (value * 1_000_000).rounded() / 1_000_000
  }

  private static func snappedToHundredths(_ value: Double) -> Double {
    (value * 100).rounded() / 100
  }
}
