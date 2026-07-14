import SwiftUI

struct SectionLabel: View {
  let title: String

  var body: some View {
    Text(title)
      .counterTextStyle(.sectionTitle, color: .secondary)
  }
}
