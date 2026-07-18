import Foundation
import SwiftData

enum WidgetSnapshotSync {
  static func publish(counter: CustomCounter, in context: ModelContext) {
    WidgetSnapshot.publish(
      title: counter.name,
      heroValue: counter.currentProgress()?.heroValue
        ?? CounterFormatting.amount(counter.currentTotal())
    )
  }
}
