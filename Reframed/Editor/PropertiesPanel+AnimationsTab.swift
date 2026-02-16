import SwiftUI

extension PropertiesPanel {
  var cursorMovementSection: some View {
    VStack(alignment: .leading, spacing: Layout.itemSpacing) {
      sectionHeader(icon: "cursorarrow.motionlines", title: "Cursor Movement")

      toggleRow("Smooth Movement", isOn: $editorState.cursorMovementEnabled)
        .onChange(of: editorState.cursorMovementEnabled) { _, _ in
          editorState.regenerateSmoothedCursor()
        }

      if editorState.cursorMovementEnabled {
        VStack(alignment: .leading, spacing: Layout.compactSpacing) {
          Text("Speed")
            .font(.system(size: 12))
            .foregroundStyle(ReframedColors.secondaryText)

          HStack(spacing: 4) {
            ForEach(CursorMovementSpeed.allCases) { speed in
              let isSelected = editorState.cursorMovementSpeed == speed
              Button {
                editorState.cursorMovementSpeed = speed
                editorState.regenerateSmoothedCursor()
              } label: {
                Text(speed.label)
                  .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                  .foregroundStyle(isSelected ? ReframedColors.primaryText : ReframedColors.secondaryText)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 6)
                  .background(
                    isSelected ? ReframedColors.selectedBackground : ReframedColors.fieldBackground,
                    in: RoundedRectangle(cornerRadius: 6)
                  )
              }
              .buttonStyle(.plain)
            }
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
