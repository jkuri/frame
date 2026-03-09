import AVFoundation
import CoreVideo

extension FrameRenderer {
  static func drawBackground(
    in context: CGContext,
    rect: CGRect,
    instruction: CompositionInstruction,
    colorSpace: CGColorSpace
  ) {
    if let bgImage = instruction.backgroundImage {
      context.saveGState()
      context.addRect(rect)
      context.clip()
      let drawRect = backgroundImageRect(
        imageSize: CGSize(width: bgImage.width, height: bgImage.height),
        in: rect,
        fillMode: instruction.backgroundImageFillMode
      )
      context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
      context.fill([rect])
      context.draw(bgImage, in: drawRect)
      context.restoreGState()
      return
    }

    let colors = instruction.backgroundColors
    guard !colors.isEmpty else {
      context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
      context.fill([rect])
      return
    }

    if colors.count == 1 {
      let c = colors[0]
      context.setFillColor(CGColor(red: c.r, green: c.g, blue: c.b, alpha: c.a))
      context.fill([rect])
      return
    }

    guard
      let resolved = makeBackgroundGradient(
        colors: colors,
        rectSize: rect.size,
        startPoint: instruction.backgroundStartPoint,
        endPoint: instruction.backgroundEndPoint,
        colorSpace: colorSpace
      )
    else {
      context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
      context.fill([rect])
      return
    }

    context.saveGState()
    context.addRect(rect)
    context.clip()
    context.drawLinearGradient(resolved.gradient, start: resolved.startPoint, end: resolved.endPoint, options: [])
    context.restoreGState()
  }
}
