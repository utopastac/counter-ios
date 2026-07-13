import SwiftUI
import SwiftData

struct CreateCounterView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  var onCreated: ((CustomCounter) -> Void)?

  @State private var name = ""
  @State private var hasGoal = false
  @State private var goalText = ""
  @State private var goalDirection: GoalDirection = .countUp
  @State private var resetPeriod: CounterResetPeriod = .daily
  @State private var resetAnchorDay = Calendar.current.firstWeekday

  var body: some View {
    NavigationStack {
      Form {
        Section("Name") {
          TextField("e.g. Protein", text: $name)
        }

        Section("Goal") {
          Toggle("Set a target", isOn: $hasGoal)
          if hasGoal {
            TextField("Target amount", text: $goalText)
              .keyboardType(.numberPad)
          }

          Picker("Direction", selection: $goalDirection) {
            ForEach(GoalDirection.allCases) { direction in
              Text(direction.label).tag(direction)
            }
          }
          Text(goalDirection.summary)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Section("Reset period") {
          Picker("Period", selection: $resetPeriod) {
            ForEach(CounterResetPeriod.allCases) { period in
              Text(period.label).tag(period)
            }
          }

          if resetPeriod == .weekly {
            Picker("Resets on", selection: $resetAnchorDay) {
              ForEach(1...7, id: \.self) { weekday in
                Text(Calendar.current.weekdaySymbols[weekday - 1]).tag(weekday)
              }
            }
          }

          if resetPeriod == .monthly {
            Picker("Resets on day", selection: $resetAnchorDay) {
              ForEach(1...28, id: \.self) { day in
                Text("\(day)").tag(day)
              }
            }
          }
        }

        Section {
          Text("Quick-add buttons can be customized after creating the counter.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .navigationTitle("New Counter")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Create") {
            createCounter()
          }
          .disabled(!canCreate)
        }
      }
      .onChange(of: resetPeriod) { _, newPeriod in
        resetAnchorDay = defaultAnchor(for: newPeriod)
      }
    }
  }

  private var canCreate: Bool {
    let trimmed = name.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return false }
    if hasGoal {
      guard let goal = parsedGoal, goal > 0 else { return false }
    }
    return true
  }

  private var parsedGoal: Int? {
    guard hasGoal else { return nil }
    return Int(goalText.trimmingCharacters(in: .whitespaces))
  }

  private func defaultAnchor(for period: CounterResetPeriod) -> Int {
    switch period {
    case .daily:
      return 1
    case .weekly:
      return Calendar.current.firstWeekday
    case .monthly:
      return 1
    }
  }

  private func createCounter() {
    let trimmed = name.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return }

    let counter = CustomCounter(
      name: trimmed,
      goal: parsedGoal,
      resetPeriod: resetPeriod,
      resetAnchorDay: resetPeriod == .daily ? 1 : resetAnchorDay,
      goalDirection: goalDirection
    )
    modelContext.insert(counter)
    onCreated?(counter)
    dismiss()
  }
}

#Preview {
  CreateCounterView()
    .modelContainer(for: CustomCounter.self, inMemory: true)
}
