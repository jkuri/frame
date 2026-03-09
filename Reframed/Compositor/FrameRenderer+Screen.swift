import AVFoundation
import CoreVideo

extension FrameRenderer {
  static func drawScreenVideo(
    in context: CGContext,
    screenImage: CGImage,
    videoRect: CGRect,
    instruction: CompositionInstruction,
    compositionTime: CMTime,
    outputHeight: Int,
    isTransitioning: Bool = false
  ) {
    if instruction.videoShadow > 0 && !isTransitioning {
      drawRoundedShadow(in: context, rect: videoRect, cornerRadius: instruction.videoCornerRadius, shadow: instruction.videoShadow)
    }

    let metadataTime = CMTimeGetSeconds(compositionTime) + instruction.trimStartSeconds
    let zoomRect = resolveZoomRect(compositionTime: compositionTime, instruction: instruction)
    context.saveGState()
    if instruction.videoCornerRadius > 0 {
      let path = CGPath(
        roundedRect: videoRect,
        cornerWidth: instruction.videoCornerRadius,
        cornerHeight: instruction.videoCornerRadius,
        transform: nil
      )
      context.addPath(path)
      context.clip()
    }

    if let zr = zoomRect, zr.width < 1.0 || zr.height < 1.0 {
      let srcW = CGFloat(screenImage.width)
      let srcH = CGFloat(screenImage.height)
      let scaleX = videoRect.width / (zr.width * srcW)
      let scaleY = videoRect.height / (zr.height * srcH)
      let drawRect = CGRect(
        x: videoRect.origin.x - zr.origin.x * srcW * scaleX,
        y: videoRect.origin.y - (1 - zr.origin.y - zr.height) * srcH * scaleY,
        width: srcW * scaleX,
        height: srcH * scaleY
      )
      if instruction.videoCornerRadius <= 0 {
        context.clip(to: videoRect)
      }
      context.draw(screenImage, in: drawRect)
    } else {
      context.draw(screenImage, in: videoRect)
    }
    context.restoreGState()

    let compositionSeconds = CMTimeGetSeconds(compositionTime)
    if instruction.isSpotlightActive(at: compositionSeconds), instruction.cursorSnapshot != nil {
      drawSpotlightOverlay(
        in: context,
        videoRect: videoRect,
        instruction: instruction,
        compositionSeconds: compositionSeconds,
        metadataTime: metadataTime,
        zoomRect: zoomRect,
        outputHeight: outputHeight
      )
    }

    if instruction.showCursor, instruction.cursorSnapshot != nil {
      drawCursorOverlay(
        in: context,
        screenImage: screenImage,
        videoRect: videoRect,
        instruction: instruction,
        metadataTime: metadataTime,
        zoomRect: zoomRect,
        outputHeight: outputHeight
      )
    }
  }
}
