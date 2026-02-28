import AVFoundation
import CoreGraphics

extension CameraVideoCompositor {
  static func drawSpotlightOverlay(
    in context: CGContext,
    videoRect: CGRect,
    instruction: CompositionInstruction,
    metadataTime: Double,
    zoomRect: CGRect?,
    outputHeight: Int
  ) {
    guard instruction.spotlightEnabled, let snapshot = instruction.cursorSnapshot else { return }

    let cursorPos = snapshot.sample(at: metadataTime)

    var relX = cursorPos.x
    var relY = cursorPos.y
    if let zr = zoomRect, zr.width < 1.0 || zr.height < 1.0 {
      relX = (relX - zr.origin.x) / zr.width
      relY = (relY - zr.origin.y) / zr.height
    }

    let pixelX = videoRect.origin.x + relX * videoRect.width
    let pixelY = videoRect.origin.y + (1 - relY) * videoRect.height

    let drawScale = videoRect.width / max(instruction.canvasSize.width, 1)
    let zoomScale: CGFloat = {
      if let zr = zoomRect, zr.width < 1.0 { return 1.0 / zr.width }
      return 1.0
    }()
    let scaledRadius = instruction.spotlightRadius * drawScale * zoomScale
    let scaledSoftness = instruction.spotlightEdgeSoftness * drawScale * zoomScale

    context.saveGState()
    if instruction.videoCornerRadius > 0 {
      let clipPath = CGPath(
        roundedRect: videoRect,
        cornerWidth: instruction.videoCornerRadius,
        cornerHeight: instruction.videoCornerRadius,
        transform: nil
      )
      context.addPath(clipPath)
      context.clip()
    } else {
      context.clip(to: videoRect)
    }

    let dimColor = CGColor(red: 0, green: 0, blue: 0, alpha: instruction.spotlightDimOpacity)
    let center = CGPoint(x: pixelX, y: pixelY)

    if scaledSoftness <= 0 {
      let path = CGMutablePath()
      path.addRect(videoRect)
      path.addEllipse(
        in: CGRect(
          x: center.x - scaledRadius,
          y: center.y - scaledRadius,
          width: scaledRadius * 2,
          height: scaledRadius * 2
        )
      )
      context.addPath(path)
      context.clip(using: .evenOdd)
      context.setFillColor(dimColor)
      context.fill(videoRect)
    } else {
      let outerRadius = scaledRadius
      let innerFrac: CGFloat = outerRadius > 0 ? max(0, (outerRadius - scaledSoftness) / outerRadius) : 0
      let clearColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0)

      let colorSpace = CGColorSpaceCreateDeviceRGB()
      let locations: [CGFloat] = [0, innerFrac, 1]
      guard
        let gradient = CGGradient(
          colorsSpace: colorSpace,
          colors: [clearColor, clearColor, dimColor] as CFArray,
          locations: locations
        )
      else {
        context.restoreGState()
        return
      }

      context.drawRadialGradient(
        gradient,
        startCenter: center,
        startRadius: 0,
        endCenter: center,
        endRadius: outerRadius,
        options: [.drawsAfterEndLocation]
      )
    }

    context.restoreGState()
  }
}
