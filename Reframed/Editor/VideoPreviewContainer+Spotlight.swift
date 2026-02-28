import AVFoundation
import AppKit

extension VideoPreviewContainer {
  func updateSpotlightOverlay(
    normalizedPosition: CGPoint,
    radius: CGFloat,
    dimOpacity: CGFloat,
    edgeSoftness: CGFloat,
    visible: Bool
  ) {
    lastSpotlightNormalizedPosition = normalizedPosition
    lastSpotlightRadius = radius
    lastSpotlightDimOpacity = dimOpacity
    lastSpotlightEdgeSoftness = edgeSoftness
    lastSpotlightVisible = visible

    applySpotlightOverlay()
  }

  func applySpotlightOverlay() {
    guard lastSpotlightVisible else {
      spotlightOverlay.update(
        pixelPosition: .zero,
        radius: 0,
        dimOpacity: 0,
        edgeSoftness: 0,
        visible: false,
        containerSize: .zero
      )
      return
    }

    let canvasRect = AVMakeRect(aspectRatio: currentCanvasSize, insideRect: bounds)
    let scaleX = canvasRect.width / max(currentCanvasSize.width, 1)
    let scaleY = canvasRect.height / max(currentCanvasSize.height, 1)
    let padH = currentPadding * currentScreenSize.width * scaleX
    let padV = currentPadding * currentScreenSize.height * scaleY

    let paddedArea = CGRect(
      x: canvasRect.origin.x + padH,
      y: canvasRect.origin.y + padV,
      width: canvasRect.width - padH * 2,
      height: canvasRect.height - padV * 2
    )
    let screenRect = AVMakeRect(aspectRatio: currentScreenSize, insideRect: paddedArea)

    let zr = currentZoomRect
    let isZoomed = zr.width < 1.0 || zr.height < 1.0

    var pos = lastSpotlightNormalizedPosition
    if isZoomed {
      pos = CGPoint(
        x: (pos.x - zr.origin.x) / zr.width,
        y: (pos.y - zr.origin.y) / zr.height
      )
    }

    let pixelX = pos.x * screenRect.width
    let pixelY = (1 - pos.y) * screenRect.height

    let zoomScale: CGFloat = isZoomed ? 1.0 / zr.width : 1.0
    let baseScale = min(scaleX, scaleY)
    let scaledRadius = lastSpotlightRadius * baseScale * zoomScale
    let scaledSoftness = lastSpotlightEdgeSoftness * baseScale * zoomScale

    spotlightOverlay.update(
      pixelPosition: CGPoint(x: pixelX, y: pixelY),
      radius: scaledRadius,
      dimOpacity: lastSpotlightDimOpacity,
      edgeSoftness: scaledSoftness,
      visible: true,
      containerSize: screenRect.size
    )
  }
}
