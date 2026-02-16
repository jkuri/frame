import SwiftUI

extension PropertiesPanel {
  enum CameraBackgroundMode: Int, CaseIterable {
    case off, remove, color, gradient, image

    var label: String {
      switch self {
      case .off: "Off"
      case .remove: "Remove"
      case .color: "Color"
      case .gradient: "Gradient"
      case .image: "Image"
      }
    }
  }

  var cameraBackgroundSection: some View {
    CameraBackgroundSectionContent(editorState: editorState)
  }
}

private struct CameraBackgroundSectionContent: View {
  @Bindable var editorState: EditorState
  @State private var camBgMode: PropertiesPanel.CameraBackgroundMode = .off
  @State private var camBgGradientId: Int = 0
  @State private var camBgColorId: String? = "Black"
  @State private var camBgImageFilename: String?

  private var swatchColumns: [GridItem] {
    Array(repeating: GridItem(.flexible(), spacing: 6), count: 8)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: Layout.itemSpacing) {
      HStack(spacing: 6) {
        Image(systemName: "person.crop.rectangle")
          .font(.system(size: 11))
          .foregroundStyle(ReframedColors.dimLabel)
        Text("Background")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(ReframedColors.primaryText)
      }

      Picker("", selection: $camBgMode) {
        ForEach(PropertiesPanel.CameraBackgroundMode.allCases, id: \.rawValue) { mode in
          Text(mode.label).tag(mode)
        }
      }
      .pickerStyle(.segmented)
      .labelsHidden()

      switch camBgMode {
      case .off:
        EmptyView()
      case .remove:
        EmptyView()
      case .color:
        LazyVGrid(columns: swatchColumns, spacing: 6) {
          ForEach(TailwindColors.all) { preset in
            Button {
              camBgColorId = preset.id
            } label: {
              RoundedRectangle(cornerRadius: 10)
                .fill(preset.swiftUIColor)
                .aspectRatio(1.0, contentMode: .fit)
                .overlay(
                  RoundedRectangle(cornerRadius: 10)
                    .stroke(camBgColorId == preset.id ? Color.blue : Color.clear, lineWidth: 2)
                    .padding(1)
                )
            }
            .buttonStyle(.plain)
          }
        }
      case .gradient:
        LazyVGrid(columns: swatchColumns, spacing: 6) {
          ForEach(GradientPresets.all) { preset in
            Button {
              camBgGradientId = preset.id
            } label: {
              RoundedRectangle(cornerRadius: 10)
                .fill(
                  LinearGradient(
                    colors: preset.colors,
                    startPoint: preset.startPoint,
                    endPoint: preset.endPoint
                  )
                )
                .aspectRatio(1.0, contentMode: .fit)
                .overlay(
                  RoundedRectangle(cornerRadius: 10)
                    .stroke(camBgGradientId == preset.id ? Color.blue : Color.clear, lineWidth: 2)
                    .padding(1)
                )
            }
            .buttonStyle(.plain)
          }
        }
      case .image:
        VStack(alignment: .leading, spacing: 8) {
          if let data = editorState.cameraBackgroundImageData, let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(maxWidth: .infinity, maxHeight: 60)
              .clipShape(RoundedRectangle(cornerRadius: 8))
          }
          Button {
            pickImageFile()
          } label: {
            HStack {
              Image(systemName: "photo.on.rectangle")
              Text(editorState.cameraBackgroundImageData != nil ? "Change Image" : "Choose Image")
            }
            .font(.system(size: 12))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(ReframedColors.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
          }
          .buttonStyle(.plain)
          .foregroundStyle(ReframedColors.primaryText)
        }
      }
    }
    .onAppear { syncCamBgMode() }
    .onChange(of: camBgMode) { _, newValue in
      updateCamBgStyle(mode: newValue)
    }
    .onChange(of: camBgGradientId) { _, newValue in
      if camBgMode == .gradient {
        editorState.cameraBackgroundStyle = .gradient(newValue)
        editorState.updateCameraBackgroundProcessing()
      }
    }
    .onChange(of: camBgColorId) { _, newValue in
      if camBgMode == .color, let id = newValue,
        let preset = TailwindColors.all.first(where: { $0.id == id })
      {
        editorState.cameraBackgroundStyle = .solidColor(preset.color)
        editorState.updateCameraBackgroundProcessing()
      }
    }
  }

  private func syncCamBgMode() {
    switch editorState.cameraBackgroundStyle {
    case .none:
      camBgMode = .off
    case .transparent:
      camBgMode = .remove
    case .solidColor(let color):
      camBgMode = .color
      if let preset = TailwindColors.all.first(where: { $0.color == color }) {
        camBgColorId = preset.id
      }
    case .gradient(let id):
      camBgMode = .gradient
      camBgGradientId = id
    case .image(let filename):
      camBgMode = .image
      camBgImageFilename = filename
    }
  }

  private func updateCamBgStyle(mode: PropertiesPanel.CameraBackgroundMode) {
    switch mode {
    case .off:
      editorState.cameraBackgroundStyle = .none
    case .remove:
      editorState.cameraBackgroundStyle = .transparent
    case .color:
      if let id = camBgColorId, let preset = TailwindColors.all.first(where: { $0.id == id }) {
        editorState.cameraBackgroundStyle = .solidColor(preset.color)
      } else {
        let first = TailwindColors.all[0]
        camBgColorId = first.id
        editorState.cameraBackgroundStyle = .solidColor(first.color)
      }
    case .gradient:
      editorState.cameraBackgroundStyle = .gradient(camBgGradientId)
    case .image:
      if case .image = editorState.cameraBackgroundStyle {
        return
      }
      if let filename = camBgImageFilename {
        editorState.cameraBackgroundStyle = .image(filename)
      }
    }
    editorState.updateCameraBackgroundProcessing()
  }

  private func pickImageFile() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.png, .jpeg, .heic, .tiff]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.begin { response in
      guard response == .OK, let url = panel.url else { return }
      DispatchQueue.main.async {
        editorState.setCameraBackgroundImage(from: url)
        if case .image(let f) = editorState.cameraBackgroundStyle {
          camBgImageFilename = f
        }
      }
    }
  }
}
