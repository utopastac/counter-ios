import Foundation

struct DailyValue: Identifiable {
  let date: Date
  let value: Double

  var id: Date { date }
}

enum HistoryPeriod: String, CaseIterable, Identifiable {
  case daily
  case weekly
  case monthly

  var id: String { rawValue }

  var title: String {
    switch self {
    case .daily: "Daily"
    case .weekly: "Weekly"
    case .monthly: "Monthly"
    }
  }

  var dayCount: Int {
    switch self {
    case .daily: 7
    case .weekly: 8
    case .monthly: 30
    }
  }
}
