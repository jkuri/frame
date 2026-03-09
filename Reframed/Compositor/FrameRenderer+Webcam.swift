import AVFoundation
import CoreVideo

extension FrameRenderer {
  static func drawWebcam(
    in context: CGContext,
    webcamImage: CGImage,
    instruction: CompositionInstruction,
    compositionTime: CMTime,
    outputWidth: Int,
    outputHeight: Int,
    isCamFullscreen: Bool,
    regionTransition: (type: RegionTransitionType, progress: CGFloat)?,
    colorSpace: CGColorSpace
  ) {
    let isFullscreenPipTransition =
      isCamFullscreen
      && (regionTransition?.type == .scale || regionTransition?.type == .slide)
      && regionTransition!.progress < 1.0

    if isFullscreenPipTransition,
      let pipCam = resolveCamera(
        instruction: instruction,
        compositionTime: compositionTime,
        outputWidth: outputWidth,
        outputHeight: outputHeight
      )
    {
      drawFullscreenScaleTransition(
        in: context,
        webcamImage: webcamImage,
        instruction: instruction,
        pipCam: pipCam,
        progress: regionTransition!.progress,
        outputWidth: outputWidth,
        outputHeight: outputHeight
      )
      return
    }

    let isCustomRegionPipTransition =
      !isCamFullscreen
      && (regionTransition?.type == .scale || regionTransition?.type == .slide)
      && regionTransition!.progress < 1.0
      && instruction.cameraCustomRegions.contains(where: { $0.timeRange.containsTime(compositionTime) })

    if isCustomRegionPipTransition,
      let customCam = resolveCamera(
        instruction: instruction,
        compositionTime: compositionTime,
        outputWidth: outputWidth,
        outputHeight: outputHeight
      ),
      let defaultRect = instruction.cameraRect
    {
      let defaultCam = ResolvedCamera(
        rect: defaultRect,
        cornerRadius: instruction.cameraCornerRadius,
        borderWidth: instruction.cameraBorderWidth,
        borderColor: instruction.cameraBorderColor,
        shadow: instruction.cameraShadow,
        mirrored: instruction.cameraMirrored
      )
      drawPipInterpolationTransition(
        in: context,
        webcamImage: webcamImage,
        fromCam: defaultCam,
        toCam: customCam,
        progress: regionTransition!.progress,
        outputHeight: outputHeight
      )
      return
    }

    if let rt = regionTransition, rt.type != .none {
      context.saveGState()
      applyWebcamTransition(
        in: context,
        transition: rt,
        instruction: instruction,
        compositionTime: compositionTime,
        outputWidth: outputWidth,
        outputHeight: outputHeight,
        isCamFullscreen: isCamFullscreen
      )
    }

    if isCamFullscreen {
      drawFullscreenWebcam(
        in: context,
        webcamImage: webcamImage,
        instruction: instruction,
        regionTransition: regionTransition,
        outputWidth: outputWidth,
        outputHeight: outputHeight,
        colorSpace: colorSpace
      )
    } else if let cam = resolveCamera(
      instruction: instruction,
      compositionTime: compositionTime,
      outputWidth: outputWidth,
      outputHeight: outputHeight
    ) {
      drawPiPWebcam(
        in: context,
        webcamImage: webcamImage,
        cam: cam,
        outputHeight: outputHeight
      )
    }

    if regionTransition != nil && regionTransition!.type != .none {
      context.restoreGState()
    }
  }

  private static func drawFullscreenScaleTransition(
    in context: CGContext,
    webcamImage: CGImage,
    instruction: CompositionInstruction,
    pipCam: ResolvedCamera,
    progress: CGFloat,
    outputWidth: Int,
    outputHeight: Int
  ) {
    let p = progress
    let canvasRect = CGRect(x: 0, y: 0, width: outputWidth, height: outputHeight)
    let webcamSize = CGSize(width: webcamImage.width, height: webcamImage.height)
    let fullRect: CGRect
    if instruction.cameraFullscreenAspect == .original {
      fullRect = canvasRect
    } else {
      let targetAspect = instruction.cameraFullscreenAspect.aspectRatio(webcamSize: webcamSize)
      let virtualSize = CGSize(width: targetAspect * 1000, height: 1000)
      let vAspect = virtualSize.width / max(virtualSize.height, 1)
      let rectAspect = canvasRect.width / max(canvasRect.height, 1)
      if vAspect > rectAspect {
        let h = canvasRect.width / max(vAspect, 0.001)
        fullRect = CGRect(
          x: canvasRect.origin.x,
          y: canvasRect.midY - h / 2,
          width: canvasRect.width,
          height: h
        )
      } else {
        let w = canvasRect.height * vAspect
        fullRect = CGRect(
          x: canvasRect.midX - w / 2,
          y: canvasRect.origin.y,
          width: w,
          height: canvasRect.height
        )
      }
    }
    let pipFlippedY = CGFloat(outputHeight) - pipCam.rect.origin.y - pipCam.rect.height
    let pipRect = CGRect(x: pipCam.rect.origin.x, y: pipFlippedY, width: pipCam.rect.width, height: pipCam.rect.height)

    let interpRect = CGRect(
      x: pipRect.origin.x + (fullRect.origin.x - pipRect.origin.x) * p,
      y: pipRect.origin.y + (fullRect.origin.y - pipRect.origin.y) * p,
      width: pipRect.width + (fullRect.width - pipRect.width) * p,
      height: pipRect.height + (fullRect.height - pipRect.height) * p
    )
    let interpRadius = pipCam.cornerRadius * (1.0 - p)
    let interpBorder = pipCam.borderWidth * (1.0 - p)

    drawClippedWebcam(
      in: context,
      image: webcamImage,
      rect: interpRect,
      cornerRadius: interpRadius,
      borderWidth: interpBorder,
      borderColor: pipCam.borderColor,
      mirrored: instruction.cameraMirrored
    )
  }

  private static func drawPipInterpolationTransition(
    in context: CGContext,
    webcamImage: CGImage,
    fromCam: ResolvedCamera,
    toCam: ResolvedCamera,
    progress: CGFloat,
    outputHeight: Int
  ) {
    let p = progress
    let fromFlippedY = CGFloat(outputHeight) - fromCam.rect.origin.y - fromCam.rect.height
    let fromRect = CGRect(
      x: fromCam.rect.origin.x,
      y: fromFlippedY,
      width: fromCam.rect.width,
      height: fromCam.rect.height
    )
    let toFlippedY = CGFloat(outputHeight) - toCam.rect.origin.y - toCam.rect.height
    let toRect = CGRect(
      x: toCam.rect.origin.x,
      y: toFlippedY,
      width: toCam.rect.width,
      height: toCam.rect.height
    )
    let interpRect = CGRect(
      x: fromRect.origin.x + (toRect.origin.x - fromRect.origin.x) * p,
      y: fromRect.origin.y + (toRect.origin.y - fromRect.origin.y) * p,
      width: fromRect.width + (toRect.width - fromRect.width) * p,
      height: fromRect.height + (toRect.height - fromRect.height) * p
    )
    let interpRadius = fromCam.cornerRadius + (toCam.cornerRadius - fromCam.cornerRadius) * p
    let interpBorder = fromCam.borderWidth + (toCam.borderWidth - fromCam.borderWidth) * p
    let interpShadow = fromCam.shadow + (toCam.shadow - fromCam.shadow) * p
    let mirrored = p < 0.5 ? fromCam.mirrored : toCam.mirrored

    if interpShadow > 0 {
      drawRoundedShadow(in: context, rect: interpRect, cornerRadius: interpRadius, shadow: interpShadow)
    }

    let borderColor = p < 0.5 ? fromCam.borderColor : toCam.borderColor
    drawClippedWebcam(
      in: context,
      image: webcamImage,
      rect: interpRect,
      cornerRadius: interpRadius,
      borderWidth: interpBorder,
      borderColor: borderColor,
      mirrored: mirrored
    )
  }

  private static func applyWebcamTransition(
    in context: CGContext,
    transition: (type: RegionTransitionType, progress: CGFloat),
    instruction: CompositionInstruction,
    compositionTime: CMTime,
    outputWidth: Int,
    outputHeight: Int,
    isCamFullscreen: Bool = false
  ) {
    switch transition.type {
    case .none:
      break
    case .fade:
      context.setAlpha(transition.progress)
    case .scale:
      let cx: CGFloat
      let cy: CGFloat
      if isCamFullscreen {
        cx = CGFloat(outputWidth) / 2
        cy = CGFloat(outputHeight) / 2
      } else if let cam = resolveCamera(
        instruction: instruction,
        compositionTime: compositionTime,
        outputWidth: outputWidth,
        outputHeight: outputHeight
      ) {
        let flippedY = CGFloat(outputHeight) - cam.rect.origin.y - cam.rect.height
        cx = cam.rect.origin.x + cam.rect.width / 2
        cy = flippedY + cam.rect.height / 2
      } else {
        cx = CGFloat(outputWidth) / 2
        cy = CGFloat(outputHeight) / 2
      }
      context.translateBy(x: cx, y: cy)
      context.scaleBy(x: transition.progress, y: transition.progress)
      context.translateBy(x: -cx, y: -cy)
    case .slide:
      let slideDistance: CGFloat
      if isCamFullscreen {
        slideDistance = CGFloat(outputHeight)
      } else if let cam = resolveCamera(
        instruction: instruction,
        compositionTime: compositionTime,
        outputWidth: outputWidth,
        outputHeight: outputHeight
      ) {
        let flippedY = CGFloat(outputHeight) - cam.rect.origin.y - cam.rect.height
        slideDistance = flippedY + cam.rect.height
      } else {
        slideDistance = CGFloat(outputHeight)
      }
      let offsetY = (1.0 - transition.progress) * slideDistance
      context.translateBy(x: 0, y: -offsetY)
    }
  }

  private static func drawFullscreenWebcam(
    in context: CGContext,
    webcamImage: CGImage,
    instruction: CompositionInstruction,
    regionTransition: (type: RegionTransitionType, progress: CGFloat)?,
    outputWidth: Int,
    outputHeight: Int,
    colorSpace: CGColorSpace
  ) {
    let fullRect = CGRect(x: 0, y: 0, width: outputWidth, height: outputHeight)
    let targetAspect = instruction.cameraFullscreenAspect.aspectRatio(
      webcamSize: CGSize(width: webcamImage.width, height: webcamImage.height)
    )
    let virtualSize: CGSize
    if instruction.cameraFullscreenAspect == .original {
      virtualSize = CGSize(width: webcamImage.width, height: webcamImage.height)
    } else {
      virtualSize = CGSize(width: targetAspect * 1000, height: 1000)
    }
    let drawRect = AVMakeRect(aspectRatio: virtualSize, insideRect: fullRect)
    context.saveGState()
    if regionTransition == nil || regionTransition!.type == .none {
      drawBackground(in: context, rect: fullRect, instruction: instruction, colorSpace: colorSpace)
    }
    context.clip(to: fullRect)
    if instruction.cameraMirrored {
      applyMirror(in: context, centerX: drawRect.midX)
    }
    let webcamSize = CGSize(width: webcamImage.width, height: webcamImage.height)
    if instruction.cameraFullscreenAspect == .original {
      context.draw(webcamImage, in: drawRect)
    } else {
      context.clip(to: drawRect)
      let imgRect: CGRect
      switch instruction.cameraFullscreenFillMode {
      case .fit:
        imgRect = AVMakeRect(aspectRatio: webcamSize, insideRect: drawRect)
      case .fill:
        imgRect = aspectFillRect(imageSize: webcamSize, in: drawRect)
      }
      context.draw(webcamImage, in: imgRect)
    }
    context.restoreGState()
  }

  private static func drawPiPWebcam(
    in context: CGContext,
    webcamImage: CGImage,
    cam: ResolvedCamera,
    outputHeight: Int
  ) {
    let flippedY = CGFloat(outputHeight) - cam.rect.origin.y - cam.rect.height
    let drawRect = CGRect(
      x: cam.rect.origin.x,
      y: flippedY,
      width: cam.rect.width,
      height: cam.rect.height
    )

    if cam.shadow > 0 {
      drawRoundedShadow(in: context, rect: drawRect, cornerRadius: cam.cornerRadius, shadow: cam.shadow)
    }

    drawClippedWebcam(
      in: context,
      image: webcamImage,
      rect: drawRect,
      cornerRadius: cam.cornerRadius,
      borderWidth: cam.borderWidth,
      borderColor: cam.borderColor,
      mirrored: cam.mirrored
    )
  }
}
