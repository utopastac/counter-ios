import SwiftUI

struct SectionLabel: View {
  let title: String

  var body: some View {
    Text(title.uppercased())
      .counterTextStyle(.sectionLabel, color: .secondary)
  }
}
