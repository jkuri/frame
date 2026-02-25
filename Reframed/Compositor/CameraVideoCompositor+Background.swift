import AVFoundation
import CoreVideo

extension CameraVideoCompositor {
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
      let imageAspect = CGFloat(bgImage.width) / CGFloat(max(bgImage.height, 1))
      let rectAspect = rect.width / max(rect.height, 1)
      let drawRect: CGRect
      switch instruction.backgroundImageFillMode {
      case .fill:
        if imageAspect > rectAspect {
          let w = rect.height * imageAspect
          drawRect = CGRect(x: rect.midX - w / 2, y: rect.origin.y, width: w, height: rect.height)
        } else {
          let h = rect.width / max(imageAspect, 0.001)
          drawRect = CGRect(x: rect.origin.x, y: rect.midY - h / 2, width: rect.width, height: h)
        }
      case .fit:
        if imageAspect > rectAspect {
          let h = rect.width / max(imageAspect, 0.001)
          drawRect = CGRect(x: rect.origin.x, y: rect.midY - h / 2, width: rect.width, height: h)
        } else {
          let w = rect.height * imageAspect
          drawRect = CGRect(x: rect.midX - w / 2, y: rect.origin.y, width: w, height: rect.height)
        }
      }
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
    else {
      context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
      context.fill([rect])
      return
    }

    let startPoint = CGPoint(
      x: rect.width * instruction.backgroundStartPoint.x,
      y: rect.height * instruction.backgroundStartPoint.y
    )
    let endPoint = CGPoint(
      x: rect.width * instruction.backgroundEndPoint.x,
      y: rect.height * instruction.backgroundEndPoint.y
    )

    context.saveGState()
    context.addRect(rect)
    context.clip()
    context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
    context.restoreGState()
  }
}
