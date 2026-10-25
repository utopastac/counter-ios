import SwiftUI

/// Sketch sheet: Dayring glass controls, with pen, pencil, highlighter, eraser, nibs, and swatches.
struct SketchSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.displayScale) private var displayScale
  @Environment(\.semanticColors) private var colors
  @Environment(\.colorScheme) private var colorScheme

  @State private var drawing = SketchDrawing.empty
  @State private var undoStack = SketchUndoStack()
  @State private var tool: SketchTool = .pen
  @State private var colorHex = SketchPalette.defaultHex
  @State private var didPickInk = false
  @State private var widthByTool: [SketchTool: Double] = Dictionary(
    uniqueKeysWithValues: SketchTool.allCases.map { ($0, $0.defaultWidth) }
  )
  @State private var canvasSize: CGSize = .zero
  @State private var didKeep = false

  let onSave: (Data) -> Void

  var body: some View {
    VStack(spacing: SpaceToken.u2) {
      CounterSheetHeader(title: "Sketch", trailingTitle: "Keep", isDoneEnabled: !drawing.isEmpty) {
        keep()
        dismiss()
      }

      SketchCanvas(
        drawing: $drawing,
        tool: tool,
        colorHex: colorHex,
        lineWidth: widthByTool[tool] ?? tool.defaultWidth,
        onWillCommitStroke: { undoStack.registerStrokeAdded() },
        onCanvasSizeChange: { canvasSize = $0 }
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .overlay(alignment: .topTrailing) {
        clearButton
      }
      .padding(.horizontal, SheetToken.horizontal)

      SketchToolbar(
        tool: $tool,
        colorHex: $colorHex,
        widthByTool: $widthByTool,
        canUndo: undoStack.canUndo,
        onUndo: { undoStack.undo(drawing: &drawing) }
      )
      .padding(.horizontal, SheetToken.horizontal)
      .padding(.bottom, SpaceToken.u2)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .counterSheetPresentation(.cornerRadiusGlass)
    .presentationDetents([.large])
    .onAppear(perform: pickInkIfNeeded)
    .onDisappear { keep() }
  }

  private var clearButton: some View {
    Button {
      undoStack.registerClear(before: drawing)
      drawing = .empty
    } label: {
      Image(systemName: "trash")
        .font(.system(size: SizeToken.iconGlyph, weight: .semibold))
        .frame(width: SizeToken.iconButtonHitArea, height: SizeToken.iconButtonHitArea)
    }
    .buttonStyle(.plain)
    .foregroundStyle(colors.textPrimary)
    .glassEffect(.regular.interactive(), in: .circle)
    .disabled(drawing.isEmpty)
    .opacity(drawing.isEmpty ? OpacityToken.disabledButton : 1)
    .accessibilityLabel("Clear")
    .padding(SpaceToken.u1)
  }

  private func pickInkIfNeeded() {
    guard !didPickInk else { return }
    didPickInk = true
    if colorScheme == .dark {
      colorHex = "#FFFFFF"
    }
  }

  private func keep() {
    guard !didKeep else { return }
    didKeep = true
    guard let data = SketchStrokeRenderer.pngData(
      of: drawing,
      size: canvasSize,
      scale: displayScale,
      background: colors.surfaceSheet
    ) else { return }
    onSave(data)
  }
}

private struct SketchToolbar: View {
  @Environment(\.semanticColors) private var colors

  @Binding var tool: SketchTool
  @Binding var colorHex: String
  @Binding var widthByTool: [SketchTool: Double]
  var canUndo: Bool
  var onUndo: () -> Void

  private let nibPreviewSizes: [CGFloat] = [8, 12, 18, 24]

  private var selectedWidth: Double {
    widthByTool[tool] ?? tool.defaultWidth
  }

  private var nibColor: Color {
    tool.isEraser ? colors.textPrimary : Color(sketchHex: colorHex)
  }

  var body: some View {
    VStack(spacing: SpaceToken.u1) {
      toolsRow
      sizesRow
      swatchesRow
    }
  }

  private var toolsRow: some View {
    HStack(spacing: SpaceToken.u1) {
      ForEach(SketchTool.toolbarOrder, id: \.self) { option in
        toolButton(option)
      }
      Spacer(minLength: SpaceToken.u1)
      undoButton
    }
  }

  private var sizesRow: some View {
    HStack(spacing: SpaceToken.u1) {
      ForEach(Array(tool.availableWidths.enumerated()), id: \.offset) { index, width in
        let selected = selectedWidth == width
        Button {
          widthByTool[tool] = width
        } label: {
          Circle()
            .fill(nibColor)
            .frame(
              width: nibPreviewSizes[min(index, nibPreviewSizes.count - 1)],
              height: nibPreviewSizes[min(index, nibPreviewSizes.count - 1)]
            )
            .overlay {
              if SketchPalette.isLightHex(colorHex), !tool.isEraser {
                Circle().strokeBorder(colors.borderColourSwatch, lineWidth: BorderToken.colourSwatch)
              }
            }
            .frame(maxWidth: .infinity)
            .frame(height: SizeToken.iconButtonHitArea)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect(glass(selected: selected), in: RadiusToken.continuousButton)
        .accessibilityLabel("Nib \(Int(width))")
        .accessibilityAddTraits(selected ? .isSelected : [])
      }
    }
  }

  private var swatchesRow: some View {
    HStack(spacing: SpaceToken.x1) {
      ForEach(SketchPalette.hexes, id: \.self) { hex in
        let selected = colorHex.caseInsensitiveCompare(hex) == .orderedSame
        Button {
          colorHex = hex
        } label: {
          Circle()
            .fill(Color(sketchHex: hex))
            .frame(width: SizeToken.iconGlyph, height: SizeToken.iconGlyph)
            .overlay {
              Circle()
                .strokeBorder(
                  selected
                    ? ComponentColor.colourSwatchBorderSelected(colors)
                    : ComponentColor.colourSwatchBorderDefault(colors),
                  lineWidth: selected ? BorderToken.selectionSelected : BorderToken.colourSwatch
                )
            }
            .frame(maxWidth: .infinity)
            .frame(height: SizeToken.iconButtonHitArea)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Color \(hex)")
        .accessibilityAddTraits(selected ? .isSelected : [])
      }
    }
  }

  private func toolButton(_ option: SketchTool) -> some View {
    let selected = tool == option
    return Button {
      tool = option
    } label: {
      Image(systemName: option.symbolName)
        .font(.system(size: SizeToken.iconGlyph, weight: .semibold))
        .frame(width: SizeToken.iconButtonHitArea, height: SizeToken.iconButtonHitArea)
    }
    .buttonStyle(.plain)
    .foregroundStyle(selected ? colors.interactivePrimaryForeground : colors.textPrimary)
    .glassEffect(glass(selected: selected), in: .circle)
    .accessibilityLabel(option.displayName)
    .accessibilityAddTraits(selected ? .isSelected : [])
  }

  private var undoButton: some View {
    Button(action: onUndo) {
      Image(systemName: "arrow.uturn.backward")
        .font(.system(size: SizeToken.iconGlyph, weight: .semibold))
        .frame(width: SizeToken.iconButtonHitArea, height: SizeToken.iconButtonHitArea)
    }
    .buttonStyle(.plain)
    .foregroundStyle(colors.textPrimary)
    .glassEffect(.regular.interactive(), in: .circle)
    .disabled(!canUndo)
    .opacity(canUndo ? 1 : OpacityToken.disabledButton)
    .accessibilityLabel("Undo")
  }

  private func glass(selected: Bool) -> Glass {
    if selected {
      .regular.tint(colors.interactivePrimaryFill).interactive()
    } else {
      .regular.interactive()
    }
  }
}
