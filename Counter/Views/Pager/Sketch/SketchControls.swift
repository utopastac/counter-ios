import SwiftUI

/// Doodleoop drawing desk: square paper, clear, tool row, nib sizes, and swatches.
struct SketchSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.displayScale) private var displayScale
  @Environment(\.designSystem) private var designSystem

  @State private var drawing = SketchDrawing.empty
  @State private var undoStack = SketchUndoStack()
  @State private var tool: SketchTool = .pen
  @State private var colorHex = SketchPalette.defaultHex
  @State private var widthByTool: [SketchTool: Double] = Dictionary(
    uniqueKeysWithValues: SketchTool.allCases.map { ($0, $0.defaultWidth) }
  )
  @State private var canvasSize: CGSize = .zero
  @State private var didKeep = false

  let onSave: (Data) -> Void

  var body: some View {
    VStack(spacing: 0) {
      CounterSheetHeader(title: "Sketch", trailingTitle: "Keep", isDoneEnabled: !drawing.isEmpty) {
        keep()
        dismiss()
      }

      Spacer(minLength: SpaceToken.u1)

      SketchCanvas(
        drawing: $drawing,
        tool: tool,
        colorHex: colorHex,
        lineWidth: widthByTool[tool] ?? tool.defaultWidth,
        onWillCommitStroke: { undoStack.registerStrokeAdded() },
        onCanvasSizeChange: { canvasSize = $0 }
      )
      .aspectRatio(1, contentMode: .fit)
      .frame(maxWidth: .infinity)
      .overlay(alignment: .topTrailing) {
        clearButton
      }
      .padding(.horizontal, SketchChrome.pageInset)

      Spacer(minLength: SpaceToken.u2)

      SketchToolbar(
        tool: $tool,
        colorHex: $colorHex,
        widthByTool: $widthByTool,
        canUndo: undoStack.canUndo,
        onUndo: { undoStack.undo(drawing: &drawing) }
      )
      .padding(.horizontal, SketchChrome.pageInset)
      .padding(.bottom, SpaceToken.u2)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(SketchChrome.paper)
    .environment(\.colorScheme, .light)
    .counterDesignSystem(
      CounterDesignSystem(
        colorScheme: .light,
        accent: designSystem.accent,
        isTintEnabled: designSystem.isTintEnabled,
        colorPackRaw: designSystem.colorPackRaw,
        fontPackRaw: designSystem.fontPackRaw
      )
    )
    .counterSheetPresentation(.cornerRadiusGlass)
    .presentationDetents([.large])
    .presentationBackground(SketchChrome.paper)
    .onDisappear { keep() }
  }

  private var clearButton: some View {
    Button {
      undoStack.registerClear(before: drawing)
      drawing = .empty
    } label: {
      Image("SketchIconTrash")
        .resizable()
        .renderingMode(.template)
        .scaledToFit()
        .frame(width: 20, height: 20)
        .foregroundStyle(SketchChrome.ink.opacity(drawing.isEmpty ? 0.35 : 1))
        .frame(width: 40, height: 40)
        .background(SketchChrome.paperWhite.opacity(drawing.isEmpty ? 0.35 : 1))
        .clipShape(RoundedRectangle(cornerRadius: SketchChrome.controlRadius, style: .circular))
    }
    .buttonStyle(.plain)
    .disabled(drawing.isEmpty)
    .accessibilityLabel("Clear")
    .padding(SpaceToken.u1)
  }

  private func keep() {
    guard !didKeep else { return }
    didKeep = true
    guard let data = SketchStrokeRenderer.pngData(
      of: drawing,
      size: canvasSize,
      scale: displayScale
    ) else { return }
    onSave(data)
  }
}

private struct SketchToolbar: View {
  @Binding var tool: SketchTool
  @Binding var colorHex: String
  @Binding var widthByTool: [SketchTool: Double]
  var canUndo: Bool
  var onUndo: () -> Void

  private let nibPreviewSizes: [CGFloat] = [12, 20, 28, 36]

  private var selectedWidth: Double {
    widthByTool[tool] ?? tool.defaultWidth
  }

  var body: some View {
    VStack(spacing: 0) {
      Rectangle()
        .fill(SketchChrome.gridLine)
        .frame(height: SketchChrome.borderThin)
      toolsRow
      sizesRow
      swatchesRow
      Rectangle()
        .fill(SketchChrome.gridLine)
        .frame(height: SketchChrome.borderThin)
    }
  }

  private var toolsRow: some View {
    HStack(spacing: 0) {
      ForEach(Array(SketchTool.toolbarOrder.enumerated()), id: \.element) { index, option in
        if index > 0 { Spacer(minLength: 0) }
        toolButton(option)
      }
      Spacer(minLength: 0)
      undoButton
    }
    .padding(.horizontal, SpaceToken.u1)
    .padding(.vertical, SpaceToken.x1)
    .frame(height: 56)
  }

  private var sizesRow: some View {
    HStack(spacing: SpaceToken.x1) {
      ForEach(Array(tool.availableWidths.enumerated()), id: \.offset) { index, width in
        Button {
          widthByTool[tool] = width
        } label: {
          let preview = nibPreviewSizes[min(index, nibPreviewSizes.count - 1)]
          ZStack {
            RoundedRectangle(cornerRadius: SketchChrome.controlRadius, style: .circular)
              .strokeBorder(
                selectedWidth == width ? SketchChrome.ink : Color.clear,
                lineWidth: SketchChrome.borderHeavy
              )
            Circle()
              .fill(tool.isEraser ? SketchChrome.ink : Color(sketchHex: colorHex))
              .frame(width: preview, height: preview)
              .overlay {
                if SketchPalette.isLightHex(colorHex) {
                  Circle().strokeBorder(SketchChrome.dot, lineWidth: SketchChrome.borderThin)
                }
              }
          }
          .frame(maxWidth: .infinity)
          .frame(height: 48)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Nib \(Int(width))")
      }
    }
    .padding(.horizontal, SpaceToken.u1)
    .padding(.vertical, SpaceToken.x1)
  }

  private var swatchesRow: some View {
    HStack {
      ForEach(SketchPalette.hexes, id: \.self) { hex in
        let selected = colorHex.caseInsensitiveCompare(hex) == .orderedSame
        Button {
          colorHex = hex
        } label: {
          Circle()
            .fill(Color(sketchHex: hex))
            .frame(width: selected ? 40 : 28, height: selected ? 40 : 28)
            .overlay {
              Circle()
                .strokeBorder(
                  selected ? SketchChrome.ink : swatchEdge(for: hex),
                  lineWidth: selected ? SketchChrome.borderHeavy : SketchChrome.borderThin
                )
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Color \(hex)")
      }
    }
    .padding(.horizontal, SpaceToken.u1)
    .padding(.vertical, SpaceToken.x1)
    .frame(height: 56)
  }

  private func toolButton(_ option: SketchTool) -> some View {
    let selected = tool == option
    return Button {
      tool = option
    } label: {
      Image(option.iconName)
        .resizable()
        .renderingMode(.template)
        .scaledToFit()
        .frame(width: 32, height: 32)
        .foregroundStyle(selected ? SketchChrome.tan : SketchChrome.ink)
        .frame(width: 48, height: 48)
        .background(selected ? SketchChrome.ink : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: SketchChrome.controlRadius, style: .circular))
    }
    .buttonStyle(.plain)
    .accessibilityLabel(option.displayName)
    .accessibilityAddTraits(selected ? .isSelected : [])
  }

  private var undoButton: some View {
    Button(action: onUndo) {
      Image("SketchIconUndo")
        .resizable()
        .renderingMode(.template)
        .scaledToFit()
        .frame(width: 32, height: 32)
        .foregroundStyle(canUndo ? SketchChrome.ink : SketchChrome.placeholder)
        .frame(width: 48, height: 48)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(!canUndo)
    .accessibilityLabel("Undo")
  }

  private func swatchEdge(for hex: String) -> Color {
    if SketchPalette.isLightHex(hex) {
      return SketchChrome.ink.opacity(0.25)
    }
    return Color(sketchHex: hex).opacity(0.55)
  }
}
