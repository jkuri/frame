import AVFoundation
import CoreVideo

extension CameraVideoCompositor {
  static func drawScreenVideo(
    in context: CGContext,
    screenImage: CGImage,
    videoRect: CGRect,
    instruction: CompositionInstruction,
    compositionTime: CMTime,
    outputHeight: Int
  ) {
    if instruction.videoShadow > 0 {
      let blur = min(videoRect.width, videoRect.height) * instruction.videoShadow / 2000.0
      context.saveGState()
      context.setShadow(
        offset: .zero,
        blur: blur,
        color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.6)
      )
      if instruction.videoCornerRadius > 0 {
        let shadowPath = CGPath(
          roundedRect: videoRect,
          cornerWidth: instruction.videoCornerRadius,
          cornerHeight: instruction.videoCornerRadius,
          transform: nil
        )
        context.addPath(shadowPath)
      } else {
        context.addRect(videoRect)
      }
      context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
      context.fillPath()
      context.restoreGState()
    }

    let metadataTime = CMTimeGetSeconds(compositionTime) + instruction.trimStartSeconds
    var zoomRect = instruction.zoomTimeline?.zoomRect(at: metadataTime)
    if instruction.zoomFollowCursor, let zr = zoomRect, zr.width < 1.0 || zr.height < 1.0,
      let snapshot = instruction.cursorSnapshot
    {
      let cursorPos = snapshot.sample(at: metadataTime)
      zoomRect = ZoomTimeline.followCursor(zr, cursorPosition: cursorPos)
    }
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
