import Foundation
import SwiftData

enum WidgetSnapshotSync {
  static func publish(counter: CustomCounter, in context: ModelContext) {
    let total = CounterPeriodCalculator.total(from: counter.entries, for: counter)
    let progress = GoalProgressCalculator.progress(
      current: total,
      goal: counter.effectiveGoal,
      direction: counter.goalDirection
    )

    WidgetSnapshot.publish(
      title: counter.name,
      heroValue: progress?.heroValue ?? "\(total)"
    )
  }
}
