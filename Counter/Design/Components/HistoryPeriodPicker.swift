import SwiftUI

struct HistoryPeriodPicker: View {
  @Environment(\.semanticColors) private var colors
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @Binding var selection: HistoryPeriod
  @Namespace private var selectionNamespace

  var body: some View {
    HStack(spacing: 0) {
      ForEach(HistoryPeriod.allCases) { period in
        periodButton(for: period)
      }
    }
    .padding(HistoryToken.periodPickerInset)
    .frame(height: HistoryToken.periodPickerHeight)
    .background(
      ComponentColor.historySegmentTrack(colors),
      in: RadiusToken.continuousButton
    )
  }

  @ViewBuilder
  private func periodButton(for period: HistoryPeriod) -> some View {
    let isSelected = selection == period

    Button {
      withAnimation(selectionAnimation) {
        selection = period
      }
    } label: {
      Text(period.segmentTitle)
        .counterTextStyle(
          .historySegment,
          color: isSelected ? .onInteractiveFill : .primary,
          compact: true
        )
        .frame(maxWidth: .infinity)
        .frame(height: HistoryToken.periodPickerHeight - HistoryToken.periodPickerInset * 2)
        .background {
          if isSelected {
            RadiusToken.continuousButton
              .fill(ComponentColor.historySegmentActiveFill(colors))
              .matchedGeometryEffect(id: "historySegmentSelection", in: selectionNamespace)
          }
        }
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  private var selectionAnimation: Animation {
    reduceMotion
      ? MotionToken.reduceMotionSettle
      : .smooth(duration: MotionToken.pagerDotDuration)
  }
}

#Preview {
  HistoryPeriodPicker(selection: .constant(.daily))
    .padding()
    .counterDesignSystem(CounterDesignSystem(colorScheme: .light, accent: nil))
}
