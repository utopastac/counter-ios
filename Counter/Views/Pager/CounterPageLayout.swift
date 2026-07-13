import SwiftUI

struct CounterPageLayout<Footer: View, EntryLog: View>: View {
  let title: String
  let heroValue: String
  let heroCaption: String
  let compactStat: String?
  let goalProgress: GoalProgress?
  @ViewBuilder var entryLog: () -> EntryLog
  @ViewBuilder var footer: () -> Footer

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        CounterPageBackground()

        VStack(alignment: .leading, spacing: 0) {
          Spacer()
            .frame(height: SpaceToken.pageTopInset)

          VStack(alignment: .leading, spacing: SpaceToken.x1) {
            Text(title)
              .counterTextStyle(.heroTitle, color: .emphasis)

            Text(heroCaption.uppercased())
              .counterTextStyle(.sectionLabel, color: .secondary)
          }

          Spacer()
            .frame(height: SpaceToken.x5)

          HStack(alignment: .center, spacing: SpaceToken.x5) {
            Text(heroValue)
              .counterTextStyle(.heroValue)
              .minimumScaleFactor(0.45)
              .lineLimit(1)
              .contentTransition(.numericText())
              .frame(maxWidth: .infinity, alignment: .leading)

            if let goalProgress {
              GoalProgressRing(
                progress: goalProgress,
                size: SizeToken.Ring.hero,
                lineWidth: SizeToken.Ring.heroStroke
              )
            }
          }

          if let compactStat {
            Text(compactStat)
              .counterTextStyle(.bodyTertiary, color: .tertiary)
              .padding(.top, SpaceToken.x3)
              .lineLimit(2)
          }

          entryLog()
            .padding(.top, SpaceToken.x3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .mask(BottomFadeMask())

          footer()
            .padding(.top, SpaceToken.x3)
            .padding(.bottom, SpaceToken.pageFooterBottom)
        }
        .padding(.horizontal, SpaceToken.pageHorizontal)
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
      }
    }
  }
}

extension CounterPageLayout where EntryLog == EmptyView {
  init(
    title: String,
    heroValue: String,
    heroCaption: String,
    compactStat: String?,
    goalProgress: GoalProgress?,
    @ViewBuilder footer: @escaping () -> Footer
  ) {
    self.title = title
    self.heroValue = heroValue
    self.heroCaption = heroCaption
    self.compactStat = compactStat
    self.goalProgress = goalProgress
    self.entryLog = { EmptyView() }
    self.footer = footer
  }
}

struct PagerDotIndicator: View {
  @Environment(\.semanticColors) private var colors

  let labels: [String]
  let selectedIndex: Int

  var body: some View {
    HStack {
      Spacer()

      VStack(spacing: SpaceToken.x2) {
        ForEach(labels.indices, id: \.self) { index in
          Capsule()
            .fill(index == selectedIndex ? ComponentColor.pagerDotActive(colors) : ComponentColor.pagerDotInactive(colors))
            .frame(width: index == selectedIndex ? 6 : 5, height: index == selectedIndex ? 18 : 5)
            .animation(.easeInOut(duration: MotionToken.pagerDotDuration), value: selectedIndex)
        }
      }
      .padding(.horizontal, 10)
      .padding(.vertical, SpaceToken.x3 + 2)
      .background {
        Capsule()
          .fill(colors.surfaceGlassFillSubtle)
          .overlay {
            Capsule()
              .strokeBorder(colors.surfaceGlassStrokeStrong, lineWidth: 1)
          }
      }
      .shadow(
        color: ShadowToken.subtle().color,
        radius: ShadowToken.subtleRadius,
        y: ShadowToken.subtleY
      )
      .padding(.trailing, SpaceToken.x4)
    }
    .padding(.bottom, SpaceToken.x6)
    .allowsHitTesting(false)
  }
}
