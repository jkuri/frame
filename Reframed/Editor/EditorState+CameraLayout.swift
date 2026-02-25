import Foundation

extension EditorState {
  func setCameraCorner(_ corner: CameraCorner) {
    let margin: CGFloat = 0.02
    let canvas = canvasSize(for: result.screenSize)
    let marginY = margin * canvas.width / max(canvas.height, 1)
    let relH = cameraRelativeHeight

    switch corner {
    case .topLeft:
      cameraLayout.relativeX = margin
      cameraLayout.relativeY = marginY
    case .topRight:
      cameraLayout.relativeX = 1.0 - cameraLayout.relativeWidth - margin
      cameraLayout.relativeY = marginY
    case .bottomLeft:
      cameraLayout.relativeX = margin
      cameraLayout.relativeY = 1.0 - relH - marginY
    case .bottomRight:
      cameraLayout.relativeX = 1.0 - cameraLayout.relativeWidth - margin
      cameraLayout.relativeY = 1.0 - relH - marginY
    }
  }

  func clampCameraPosition() {
    cameraLayout.relativeWidth = min(cameraLayout.relativeWidth, maxCameraRelativeWidth)
    let relH = cameraRelativeHeight
    cameraLayout.relativeX = max(0, min(1 - cameraLayout.relativeWidth, cameraLayout.relativeX))
    cameraLayout.relativeY = max(0, min(1 - relH, cameraLayout.relativeY))
  }

  var maxCameraRelativeWidth: CGFloat {
    maxCameraRelativeWidth(for: cameraAspect)
  }

  func maxCameraRelativeWidth(for aspect: CameraAspect) -> CGFloat {
    guard let ws = result.webcamSize else { return 1.0 }
    let canvas = canvasSize(for: result.screenSize)
    let hwRatio = aspect.heightToWidthRatio(webcamSize: ws)
    let canvasRatio = canvas.width / max(canvas.height, 1)
    return min(1.0, 1.0 / max(hwRatio * canvasRatio, 0.001))
  }

  var cameraRelativeHeight: CGFloat {
    guard let ws = result.webcamSize else { return cameraLayout.relativeWidth * 0.75 }
    let canvas = canvasSize(for: result.screenSize)
    let aspect = cameraAspect.heightToWidthRatio(webcamSize: ws)
    return cameraLayout.relativeWidth * aspect * (canvas.width / max(canvas.height, 1))
  }

  func canvasSize(for screenSize: CGSize) -> CGSize {
    if let base = canvasAspect.size(for: screenSize) {
      return base
    }
    if padding > 0 {
      let scale = 1.0 + 2.0 * padding
      return CGSize(width: screenSize.width * scale, height: screenSize.height * scale)
    }
    return screenSize
  }
}
