import Foundation
import SwiftData
import UniformTypeIdentifiers

/// Builds a CSV backup of every counter and entry for share/export.
nonisolated enum CounterExport {
  static let contentType = UTType.commaSeparatedText

  static func csvFilename(date: Date = .now) -> String {
    let stamp = date.formatted(
      Date.FormatStyle()
        .year()
        .month(.twoDigits)
        .day(.twoDigits)
        .hour(.twoDigits(amPM: .omitted))
        .minute(.twoDigits)
        .locale(Locale(identifier: "en_US_POSIX"))
    )
    let safe = stamp
      .replacingOccurrences(of: "/", with: "-")
      .replacingOccurrences(of: ", ", with: "_")
      .replacingOccurrences(of: ":", with: "")
      .replacingOccurrences(of: " ", with: "_")
    return "Numo-export-\(safe).csv"
  }

  @MainActor
  static func csvString(counters: [CustomCounter]) -> String {
    var rows: [String] = [
      "counter_id,counter_name,unit,goal,direction,reset_period,entry_id,entry_value,entry_timestamp"
    ]

    let sortedCounters = counters.sorted {
      if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
      return $0.createdAt < $1.createdAt
    }

    for counter in sortedCounters {
      let entries = counter.entries.sorted { $0.timestamp < $1.timestamp }
      if entries.isEmpty {
        rows.append(
          csvRow([
            counter.id.uuidString,
            counter.name,
            counter.unit,
            counter.effectiveGoal.map(CounterFormatting.amount) ?? "",
            counter.goalDirection.rawValue,
            counter.resetPeriod.rawValue,
            "",
            "",
            ""
          ])
        )
        continue
      }

      for entry in entries {
        rows.append(
          csvRow([
            counter.id.uuidString,
            counter.name,
            counter.unit,
            counter.effectiveGoal.map(CounterFormatting.amount) ?? "",
            counter.goalDirection.rawValue,
            counter.resetPeriod.rawValue,
            entry.id.uuidString,
            CounterFormatting.amount(entry.amount),
            iso8601String(from: entry.timestamp)
          ])
        )
      }
    }

    return rows.joined(separator: "\n") + "\n"
  }

  @MainActor
  static func csvData(counters: [CustomCounter]) -> Data {
    Data(csvString(counters: counters).utf8)
  }

  private static func iso8601String(from date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.string(from: date)
  }

  private static func csvRow(_ fields: [String]) -> String {
    fields.map(escape).joined(separator: ",")
  }

  private static func escape(_ field: String) -> String {
    if field.contains(",") || field.contains("\"") || field.contains("\n") {
      return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
    return field
  }
}
