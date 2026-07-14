import SwiftUI

struct CounterListCard: View {
  @Environment(\.colorScheme) private var colorScheme

  let accent: CounterAccent
  let title: String
  let value: String
  let caption: String
  let ringProgress: GoalProgress
  let action: () -> Void

  private var palette: CounterPaletteSlot {
    accent.palette
  }

  var body: some View {
    Button(action: action) {
      HStack(alignment: .center, spacing: SpaceToken.x4) {
        VStack(alignment: .leading, spacing: -SpaceToken.x1) {
          Text(title)
            .counterTextStyle(.listCardTitle, compact: true)

          Text(value)
            .counterTextStyle(.listCardNumber, compact: true)
            .minimumScaleFactor(0.7)
            .lineLimit(1)

          Text(caption)
            .counterTextStyle(.listCardCaption, compact: true)
        }

        Spacer(minLength: SpaceToken.x4)

        GoalProgressRing(
          progress: ringProgress,
          size: SizeToken.Ring.display,
          lineWidth: SizeToken.Ring.displayStroke,
          trackColor: palette.progressRingTrack(for: colorScheme),
          fillColor: palette.foreground(for: colorScheme)
        )
      }
      .padding(.horizontal, SpaceToken.componentPadding)
      .padding(.vertical, SpaceToken.componentPadding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        palette.background(for: colorScheme),
        in: RadiusToken.continuousListCard
      )
      .counterAccent(accent)
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  VStack(spacing: SpaceToken.x4) {
    CounterListCard(
      accent: .forCustomCounter(at: 0),
      title: "Calories",
      value: "2424",
      caption: "Remaining",
      ringProgress: GoalProgress(current: 1800, goal: 2200, direction: .countDown)
    ) {}

    CounterListCard(
      accent: .forCustomCounter(at: 0),
      title: "Protein",
      value: "80",
      caption: "To go",
      ringProgress: GoalProgress(current: 70, goal: 150, direction: .countUp)
    ) {}
  }
  .padding()
  .background(Color.white)
}
