import SwiftUI

struct CounterPageLayout<Footer: View>: View {
  let title: String
  let heroValue: String
  let heroCaption: String
  let compactStat: String?
  let goalProgress: GoalProgress?
  let palette: CounterTheme.Palette
  @ViewBuilder var footer: () -> Footer

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        CounterPageBackground(palette: palette)

        VStack(alignment: .leading, spacing: 0) {
          Spacer()
            .frame(height: 64)

          VStack(alignment: .leading, spacing: 4) {
            Text(title)
              .font(.system(size: 30, weight: .thin, design: .rounded))
              .foregroundStyle(.white.opacity(0.95))

            Text(heroCaption.uppercased())
              .font(.caption.weight(.semibold))
              .tracking(1.1)
              .foregroundStyle(.white.opacity(0.55))
          }

          Spacer()
            .frame(height: 20)

          HStack(alignment: .center, spacing: 20) {
            Text(heroValue)
              .font(.system(size: 72, weight: .ultraLight, design: .rounded))
              .foregroundStyle(.white)
              .minimumScaleFactor(0.45)
              .lineLimit(1)
              .contentTransition(.numericText())
              .frame(maxWidth: .infinity, alignment: .leading)

            if let goalProgress {
              GoalProgressRing(progress: goalProgress, size: 76, lineWidth: 8)
            }
          }

          if let compactStat {
            Text(compactStat)
              .font(.subheadline)
              .foregroundStyle(.white.opacity(0.65))
              .padding(.top, 12)
              .lineLimit(2)
          }

          Spacer(minLength: 16)

          footer()
            .padding(.bottom, 56)
        }
        .padding(.horizontal, 24)
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
      }
    }
    .preferredColorScheme(.dark)
  }
}

struct PagerDotIndicator: View {
  let labels: [String]
  let selectedIndex: Int

  var body: some View {
    HStack {
      Spacer()

      VStack(spacing: 8) {
        ForEach(labels.indices, id: \.self) { index in
          Capsule()
            .fill(index == selectedIndex ? Color.white : Color.white.opacity(0.35))
            .frame(width: index == selectedIndex ? 6 : 5, height: index == selectedIndex ? 18 : 5)
            .animation(.easeInOut(duration: 0.2), value: selectedIndex)
        }
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 14)
      .background {
        Capsule()
          .fill(.ultraThinMaterial)
          .overlay {
            Capsule()
              .strokeBorder(.white.opacity(0.18), lineWidth: 1)
          }
      }
      .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
      .padding(.trailing, 16)
    }
    .padding(.bottom, 24)
    .allowsHitTesting(false)
  }
}
