import AVFoundation
import CoreVideo
import VideoToolbox

extension FrameRenderer {
  struct TransitionState {
    let type: RegionTransitionType
    let progress: CGFloat
  }

  struct FrameState {
    let width: Int
    let height: Int
    let canvasRect: CGRect
    let paddedArea: CGRect
    let videoRect: CGRect
    let isCamFullscreen: Bool
    let screenTransition: TransitionState?
    let isScreenTransitioning: Bool
    let webcamFullyHidden: Bool
    let webcamRegionTransition: TransitionState?
  }

  struct ResolvedCamera {
    let rect: CGRect
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    let borderColor: CGColor
    let shadow: CGFloat
    let mirrored: Bool
  }

  struct ResolvedGradient {
    let gradient: CGGradient
    let startPoint: CGPoint
    let endPoint: CGPoint
  }

  // MARK: - Transition Helpers

  static func computeRegionTransition(
    compositionTime: CMTime,
    region: RegionTransitionInfo
  ) -> CGFloat {
    let t = CMTimeGetSeconds(compositionTime)
    let start = CMTimeGetSeconds(region.timeRange.start)
    let end = CMTimeGetSeconds(region.timeRange.end)
    let elapsed = t - start
    let remaining = end - t
    if region.entryTransition != .none && elapsed < region.entryDuration {
      return smoothstep(elapsed / region.entryDuration)
    }
    if region.exitTransition != .none && remaining < region.exitDuration {
      return smoothstep(remaining / region.exitDuration)
    }
    return 1.0
  }

  static func resolveActiveTransitionType(
    compositionTime: CMTime,
    region: RegionTransitionInfo
  ) -> RegionTransitionType {
    let t = CMTimeGetSeconds(compositionTime)
    let start = CMTimeGetSeconds(region.timeRange.start)
    let end = CMTimeGetSeconds(region.timeRange.end)
    let elapsed = t - start
    let remaining = end - t
    if region.entryTransition != .none && elapsed < region.entryDuration {
      return region.entryTransition
    }
    if region.exitTransition != .none && remaining < region.exitDuration {
      return region.exitTransition
    }
    return .none
  }

  // MARK: - Resolve Helpers

  static func resolveZoomRect(
    compositionTime: CMTime,
    instruction: CompositionInstruction
  ) -> CGRect? {
    let metadataTime = CMTimeGetSeconds(compositionTime) + instruction.trimStartSeconds
    var zoomRect = instruction.zoomTimeline?.zoomRect(at: metadataTime)
    if instruction.zoomFollowCursor, let zr = zoomRect, zr.width < 1.0 || zr.height < 1.0,
      let snapshot = instruction.cursorSnapshot
    {
      let cursorPos = snapshot.sample(at: metadataTime)
      zoomRect = ZoomTimeline.followCursor(zr, cursorPosition: cursorPos)
    }
    return zoomRect
  }

  static func resolveCamera(
    instruction: CompositionInstruction,
    compositionTime: CMTime,
    outputWidth: Int,
    outputHeight: Int
  ) -> ResolvedCamera? {
    let canvasSize = instruction.canvasSize
    let scaleX = CGFloat(outputWidth) / canvasSize.width
    let scaleY = CGFloat(outputHeight) / canvasSize.height
    let scale = min(scaleX, scaleY)

    if let region = instruction.cameraCustomRegions.first(where: { $0.timeRange.containsTime(compositionTime) }),
      let ws = instruction.webcamSize
    {
      let pixelRect = region.layout.pixelRect(
        screenSize: canvasSize,
        webcamSize: ws,
        cameraAspect: region.cameraAspect
      )

      let scaledRect = CGRect(
        x: pixelRect.origin.x * scaleX,
        y: pixelRect.origin.y * scaleY,
        width: pixelRect.width * scaleX,
        height: pixelRect.height * scaleY
      )

      let minDim = min(scaledRect.width, scaledRect.height)

      return ResolvedCamera(
        rect: scaledRect,
        cornerRadius: minDim * (region.cornerRadius / 100.0),
        borderWidth: region.borderWidth * scale,
        borderColor: region.borderColor,
        shadow: region.shadow,
        mirrored: region.mirrored
      )
    }

    guard let rect = instruction.cameraRect else { return nil }

    return ResolvedCamera(
      rect: rect,
      cornerRadius: instruction.cameraCornerRadius,
      borderWidth: instruction.cameraBorderWidth,
      borderColor: instruction.cameraBorderColor,
      shadow: instruction.cameraShadow,
      mirrored: instruction.cameraMirrored
    )
  }

  // MARK: - Geometry Helpers

  static func backgroundImageRect(
    imageSize: CGSize,
    in rect: CGRect,
    fillMode: BackgroundImageFillMode
  ) -> CGRect {
    switch fillMode {
    case .fill:
      return aspectFillRect(imageSize: imageSize, in: rect)
    case .fit:
      return AVMakeRect(aspectRatio: imageSize, insideRect: rect)
    }
  }

  static func aspectFillRect(imageSize: CGSize, in rect: CGRect) -> CGRect {
    let imageAspect = imageSize.width / max(imageSize.height, 1)
    let rectAspect = rect.width / max(rect.height, 1)

    if imageAspect > rectAspect {
      let w = rect.height * imageAspect
      return CGRect(x: rect.midX - w / 2, y: rect.origin.y, width: w, height: rect.height)
    } else {
      let h = rect.width / max(imageAspect, 0.001)
      return CGRect(x: rect.origin.x, y: rect.midY - h / 2, width: rect.width, height: h)
    }
  }

  // MARK: - Gradient

  static func makeBackgroundGradient(
    colors: [(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)],
    rectSize: CGSize,
    startPoint: CGPoint,
    endPoint: CGPoint,
    colorSpace: CGColorSpace
  ) -> ResolvedGradient? {
    let cgColors = colors.map { CGColor(red: $0.r, green: $0.g, blue: $0.b, alpha: $0.a) }
    let locations: [CGFloat] = colors.enumerated().map { i, _ in
      CGFloat(i) / CGFloat(max(colors.count - 1, 1))
    }
    guard
      let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: cgColors as CFArray,
        locations: locations
      )
    else { return nil }
    return ResolvedGradient(
      gradient: gradient,
      startPoint: CGPoint(x: rectSize.width * startPoint.x, y: rectSize.height * startPoint.y),
      endPoint: CGPoint(x: rectSize.width * endPoint.x, y: rectSize.height * endPoint.y)
    )
  }

  // MARK: - Drawing Primitives

  static func shadowBlur(rect: CGRect, shadow: CGFloat) -> CGFloat {
    min(rect.width, rect.height) * shadow / 2000.0
  }

  static func applyMirror(in context: CGContext, centerX: CGFloat) {
    context.translateBy(x: centerX, y: 0)
    context.scaleBy(x: -1, y: 1)
    context.translateBy(x: -centerX, y: 0)
  }

  static func drawRoundedShadow(
    in context: CGContext,
    rect: CGRect,
    cornerRadius: CGFloat,
    shadow: CGFloat
  ) {
    let blur = shadowBlur(rect: rect, shadow: shadow)
    context.saveGState()
    context.setShadow(
      offset: .zero,
      blur: blur,
      color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.6)
    )
    if cornerRadius > 0 {
      let path = CGPath(
        roundedRect: rect,
        cornerWidth: cornerRadius,
        cornerHeight: cornerRadius,
        transform: nil
      )
      context.addPath(path)
    } else {
      context.addRect(rect)
    }
    context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
    context.fillPath()
    context.restoreGState()
  }

  static func drawClippedWebcam(
    in context: CGContext,
    image: CGImage,
    rect: CGRect,
    cornerRadius: CGFloat,
    borderWidth: CGFloat = 0,
    borderColor: CGColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1),
    mirrored: Bool = false
  ) {
    if borderWidth > 0 {
      let borderPath = CGPath(
        roundedRect: rect,
        cornerWidth: cornerRadius,
        cornerHeight: cornerRadius,
        transform: nil
      )
      context.saveGState()
      context.addPath(borderPath)
      context.setFillColor(borderColor)
      context.fillPath()
      context.restoreGState()

      let insetRect = rect.insetBy(dx: borderWidth, dy: borderWidth)
      let innerRadius = max(0, cornerRadius - borderWidth)
      let innerPath = CGPath(
        roundedRect: insetRect,
        cornerWidth: innerRadius,
        cornerHeight: innerRadius,
        transform: nil
      )
      context.saveGState()
      context.addPath(innerPath)
      context.clip()
      if mirrored { applyMirror(in: context, centerX: insetRect.midX) }
      let fillRect = aspectFillRect(imageSize: CGSize(width: image.width, height: image.height), in: insetRect)
      context.draw(image, in: fillRect)
      context.restoreGState()
    } else {
      let path = CGPath(
        roundedRect: rect,
        cornerWidth: cornerRadius,
        cornerHeight: cornerRadius,
        transform: nil
      )
      context.saveGState()
      context.addPath(path)
      context.clip()
      if mirrored { applyMirror(in: context, centerX: rect.midX) }
      let fillRect = aspectFillRect(imageSize: CGSize(width: image.width, height: image.height), in: rect)
      context.draw(image, in: fillRect)
      context.restoreGState()
    }
  }

  // MARK: - Pixel Buffer Utilities

  static func makeBitmapContext(
    for pixelBuffer: CVPixelBuffer,
    colorSpace: CGColorSpace,
    bitsPerComponent: Int,
    bitmapInfo: UInt32
  ) -> CGContext? {
    guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }

    return CGContext(
      data: baseAddress,
      width: CVPixelBufferGetWidth(pixelBuffer),
      height: CVPixelBufferGetHeight(pixelBuffer),
      bitsPerComponent: bitsPerComponent,
      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
      space: colorSpace,
      bitmapInfo: bitmapInfo
    )
  }

  static func createImage(from pixelBuffer: CVPixelBuffer) -> CGImage? {
    var imageOut: CGImage?
    let status = VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &imageOut)
    guard status == noErr else { return nil }
    return imageOut
  }
}
