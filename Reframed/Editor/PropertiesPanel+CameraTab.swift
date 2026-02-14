import SwiftUI

extension PropertiesPanel {
  var cameraSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      sectionHeader(icon: "pip", title: "Camera")

      HStack(spacing: 4) {
        ForEach(
          Array(
            zip(
              [CameraCorner.topLeft, .topRight, .bottomLeft, .bottomRight],
              ["arrow.up.left", "arrow.up.right", "arrow.down.left", "arrow.down.right"]
            )
          ),
          id: \.1
        ) { corner, icon in
          Button {
            editorState.setCameraCorner(corner)
          } label: {
            Image(systemName: icon)
              .font(.system(size: 11))
              .frame(width: 28, height: 28)
              .background(ReframedColors.fieldBackground)
              .clipShape(RoundedRectangle(cornerRadius: 4))
          }
          .buttonStyle(.plain)
          .foregroundStyle(ReframedColors.primaryText)
        }
      }

      HStack(spacing: 8) {
        Text("Size")
          .font(.system(size: 12))
          .foregroundStyle(ReframedColors.secondaryText)
        Slider(value: $editorState.cameraLayout.relativeWidth, in: 0.1...1.0, step: 0.01)
          .onChange(of: editorState.cameraLayout.relativeWidth) { _, _ in
            editorState.clampCameraPosition()
          }
      }

      HStack(spacing: 8) {
        Text("Radius")
          .font(.system(size: 12))
          .foregroundStyle(ReframedColors.secondaryText)
        Slider(value: $editorState.cameraCornerRadius, in: 0...50, step: 1)
        Text("\(Int(editorState.cameraCornerRadius))%")
          .font(.system(size: 12, design: .monospaced))
          .foregroundStyle(ReframedColors.secondaryText)
          .frame(width: 36, alignment: .trailing)
      }

      HStack(spacing: 8) {
        Text("Border")
          .font(.system(size: 12))
          .foregroundStyle(ReframedColors.secondaryText)
        Slider(value: $editorState.cameraBorderWidth, in: 0...10, step: 0.5)
        Text(String(format: "%.1f", editorState.cameraBorderWidth))
          .font(.system(size: 12, design: .monospaced))
          .foregroundStyle(ReframedColors.secondaryText)
          .frame(width: 36, alignment: .trailing)
      }
    }
  }
}
