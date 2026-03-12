import SwiftUI
import AppKit

extension PropertiesPanel {
  var canvasSection: some View {
    VStack(alignment: .leading, spacing: Layout.itemSpacing) {
      SectionHeader(icon: "rectangle.dashed", title: "Canvas")

      SegmentPicker(
        items: CanvasAspect.allCases,
        label: { $0.label },
        selection: $editorState.canvasAspect
      )
      .onChange(of: editorState.canvasAspect) { _, _ in
        editorState.clampCameraPosition()
      }
    }
  }

  func syncBackgroundMode() {
    switch editorState.backgroundStyle {
    case .none:
      backgroundMode = .color
      selectedColorId = "Black"
      editorState.backgroundStyle = .solidColor(CodableColor(r: 0, g: 0, b: 0))
    case .gradient(let id):
      backgroundMode = .gradient
      selectedGradientId = id
    case .solidColor(let color):
      backgroundMode = .color
      if let preset = TailwindColors.all.first(where: { $0.color == color }) {
        selectedColorId = preset.id
      }
    case .image(let filename):
      backgroundMode = .image
      backgroundImageFilename = filename
    }
  }

  func updateBackgroundStyle(mode: BackgroundMode) {
    switch mode {
    case .gradient:
      editorState.backgroundStyle = .gradient(selectedGradientId)
    case .color:
      if let id = selectedColorId, let preset = TailwindColors.all.first(where: { $0.id == id }) {
        editorState.backgroundStyle = .solidColor(preset.color)
      } else {
        let first = TailwindColors.all[0]
        selectedColorId = first.id
        editorState.backgroundStyle = .solidColor(first.color)
      }
    case .image:
      if case .image = editorState.backgroundStyle {
        return
      }
      if let filename = backgroundImageFilename {
        editorState.backgroundStyle = .image(filename)
      }
    }
  }

  func syncCameraBackgroundMode() {
    switch editorState.cameraBackgroundStyle {
    case .none:
      cameraBackgroundMode = .none
    case .blur(let intensity):
      cameraBackgroundMode = .blur
      cameraBlurIntensity = intensity
    case .solidColor(let color):
      cameraBackgroundMode = .color
      if let preset = TailwindColors.all.first(where: { $0.color == color }) {
        selectedCameraColorId = preset.id
      }
    case .gradient(let id):
      cameraBackgroundMode = .gradient
      selectedCameraGradientId = id
    case .image(let filename):
      cameraBackgroundMode = .image
      cameraBackgroundImageFilename = filename
    }
  }

  func updateCameraBackgroundStyle(mode: CameraBackgroundMode) {
    switch mode {
    case .none:
      editorState.cameraBackgroundStyle = .none
    case .blur:
      editorState.cameraBackgroundStyle = .blur(cameraBlurIntensity)
    case .color:
      if let id = selectedCameraColorId, let preset = TailwindColors.all.first(where: { $0.id == id }) {
        editorState.cameraBackgroundStyle = .solidColor(preset.color)
      } else {
        let first = TailwindColors.all[0]
        selectedCameraColorId = first.id
        editorState.cameraBackgroundStyle = .solidColor(first.color)
      }
    case .gradient:
      editorState.cameraBackgroundStyle = .gradient(selectedCameraGradientId)
    case .image:
      if case .image = editorState.cameraBackgroundStyle {
        return
      }
      if let filename = cameraBackgroundImageFilename {
        editorState.cameraBackgroundStyle = .image(filename)
      }
    }
  }

  func pickCameraBackgroundImage() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.png, .jpeg, .heic, .tiff]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.begin { response in
      guard response == .OK, let url = panel.url else { return }
      DispatchQueue.main.async {
        self.editorState.setCameraBackgroundImage(from: url)
        if case .image(let f) = self.editorState.cameraBackgroundStyle {
          self.cameraBackgroundImageFilename = f
        }
      }
    }
  }

  func pickBackgroundImage() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.png, .jpeg, .heic, .tiff]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.begin { response in
      guard response == .OK, let url = panel.url else { return }
      DispatchQueue.main.async {
        self.editorState.setBackgroundImage(from: url)
        if case .image(let f) = self.editorState.backgroundStyle {
          self.backgroundImageFilename = f
        }
      }
    }
  }
}
