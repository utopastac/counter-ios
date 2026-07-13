import SwiftUI
import SwiftData

struct CustomCountersListView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \CustomCounter.createdAt) private var counters: [CustomCounter]

  @State private var showCreateSheet = false

  var body: some View {
    NavigationStack {
      Group {
        if counters.isEmpty {
          ContentUnavailableView {
            Label("No Counters", systemImage: "number.square")
          } description: {
            Text("Create counters for protein, carbs, water, or anything you want to track daily.")
          } actions: {
            Button("Create Counter") {
              showCreateSheet = true
            }
            .buttonStyle(.borderedProminent)
          }
        } else {
          List {
            ForEach(counters) { counter in
              NavigationLink {
                CustomCounterDetailView(counter: counter)
              } label: {
                VStack(alignment: .leading, spacing: 4) {
                  Text(counter.name)
                    .font(.headline)
                  Text("Resets daily")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
              }
            }
            .onDelete(perform: deleteCounters)
          }
        }
      }
      .navigationTitle("Custom Counters")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            showCreateSheet = true
          } label: {
            Label("Add", systemImage: "plus")
          }
        }
      }
      .sheet(isPresented: $showCreateSheet) {
        CreateCounterView()
      }
    }
  }

  private func deleteCounters(at offsets: IndexSet) {
    for index in offsets {
      modelContext.delete(counters[index])
    }
  }
}

#Preview {
  CustomCountersListView()
    .modelContainer(for: CustomCounter.self, inMemory: true)
}
