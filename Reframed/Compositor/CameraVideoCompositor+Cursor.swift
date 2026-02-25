import AVFoundation
import CoreVideo

extension CameraVideoCompositor {
  static func drawCursorOverlay(
    in context: CGContext,
    screenImage: CGImage,
    videoRect: CGRect,
    instruction: CompositionInstruction,
    metadataTime: Double,
    zoomRect: CGRect?,
    outputHeight: Int
  ) {
    guard let snapshot = instruction.cursorSnapshot else { return }

    context.saveGState()
    context.translateBy(x: 0, y: CGFloat(outputHeight))
    context.scaleBy(x: 1, y: -1)

    let flippedVideoRect = CGRect(
      x: videoRect.origin.x,
      y: CGFloat(outputHeight) - videoRect.origin.y - videoRect.height,
      width: videoRect.width,
      height: videoRect.height
    )

    let cursorPos = snapshot.sample(at: metadataTime)

    var pixelX: CGFloat
    var pixelY: CGFloat

    if let zr = zoomRect, zr.width < 1.0 || zr.height < 1.0 {
      let relX = (cursorPos.x - zr.origin.x) / zr.width
      let relY = (cursorPos.y - zr.origin.y) / zr.height
      pixelX = flippedVideoRect.origin.x + relX * flippedVideoRect.width
      pixelY = flippedVideoRect.origin.y + relY * flippedVideoRect.height
    } else {
      pixelX = flippedVideoRect.origin.x + cursorPos.x * flippedVideoRect.width
      pixelY = flippedVideoRect.origin.y + cursorPos.y * flippedVideoRect.height
    }

    let drawScale = flippedVideoRect.width / max(CGFloat(screenImage.width), 1)
    let zoomScale: CGFloat = {
      if let zr = zoomRect, zr.width < 1.0 { return 1.0 / zr.width }
      return 1.0
    }()

    CursorRenderer.drawCursor(
      in: context,
      position: CGPoint(x: pixelX, y: pixelY),
      style: instruction.cursorStyle,
      size: instruction.cursorSize * drawScale * zoomScale
    )

    if instruction.showClickHighlights {
      let clicks = snapshot.activeClicks(at: metadataTime)
      for (clickPoint, progress) in clicks {
        var clickPixelX: CGFloat
        var clickPixelY: CGFloat

        if let zr = zoomRect, zr.width < 1.0 || zr.height < 1.0 {
          let relX = (clickPoint.x - zr.origin.x) / zr.width
          let relY = (clickPoint.y - zr.origin.y) / zr.height
          clickPixelX = flippedVideoRect.origin.x + relX * flippedVideoRect.width
          clickPixelY = flippedVideoRect.origin.y + relY * flippedVideoRect.height
        } else {
          clickPixelX = flippedVideoRect.origin.x + clickPoint.x * flippedVideoRect.width
          clickPixelY = flippedVideoRect.origin.y + clickPoint.y * flippedVideoRect.height
        }

        CursorRenderer.drawClickHighlight(
          in: context,
          position: CGPoint(x: clickPixelX, y: clickPixelY),
          progress: progress,
          size: instruction.clickHighlightSize * drawScale * zoomScale,
          color: instruction.clickHighlightColor
        )
      }
    }

    context.restoreGState()
  }
}
