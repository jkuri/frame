import SwiftUI

extension PropertiesPanel {
  var cursorMovementSection: some View {
    VStack(alignment: .leading, spacing: Layout.itemSpacing) {
      SectionHeader(icon: "cursorarrow.motionlines", title: "Cursor Movement")

      ToggleRow(label: "Smooth Movement", isOn: $editorState.cursorMovementEnabled)
        .onChange(of: editorState.cursorMovementEnabled) { _, _ in
          editorState.regenerateSmoothedCursor()
        }

      if editorState.cursorMovementEnabled {
        VStack(alignment: .leading, spacing: Layout.compactSpacing) {
          Text("Speed")
            .font(.system(size: 12))
            .foregroundStyle(ReframedColors.secondaryText)

          SegmentPicker(
            items: CursorMovementSpeed.allCases,
            label: { $0.label },
            selection: $editorState.cursorMovementSpeed
          )
          .onChange(of: editorState.cursorMovementSpeed) { _, _ in
            editorState.regenerateSmoothedCursor()
          }
        }

        springParametersInfo
      }
    }
  }

  private var springParametersInfo: some View {
    let speed = editorState.cursorMovementSpeed
    return VStack(spacing: Layout.compactSpacing) {
      infoParam("Tension", value: String(format: "%.0f", speed.tension))
      infoParam("Friction", value: String(format: "%.0f", speed.friction))
      infoParam("Mass", value: String(format: "%.1f", speed.mass))
    }
    .padding(.top, 4)
  }

  private func infoParam(_ label: String, value: String) -> some View {
    HStack {
      Text(label)
        .font(.system(size: 11))
        .foregroundStyle(ReframedColors.dimLabel)
      Spacer()
      Text(value)
        .font(.system(size: 11, design: .monospaced))
        .foregroundStyle(ReframedColors.secondaryText)
    }
  }
}
