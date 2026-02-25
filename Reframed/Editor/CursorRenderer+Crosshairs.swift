import CoreGraphics

extension CursorRenderer {
  static func drawCrosshairCursor(in context: CGContext, at point: CGPoint, size: CGFloat) {
    let halfLen = size / 2
    let gap = size * 0.15
    let lineWidth = max(1.5, size / 16)

    context.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
    context.setLineWidth(lineWidth + 1)

    let lines: [(CGPoint, CGPoint)] = [
      (CGPoint(x: point.x - halfLen, y: point.y), CGPoint(x: point.x - gap, y: point.y)),
      (CGPoint(x: point.x + gap, y: point.y), CGPoint(x: point.x + halfLen, y: point.y)),
      (CGPoint(x: point.x, y: point.y - halfLen), CGPoint(x: point.x, y: point.y - gap)),
      (CGPoint(x: point.x, y: point.y + gap), CGPoint(x: point.x, y: point.y + halfLen)),
    ]

    for (start, end) in lines {
      context.move(to: start)
      context.addLine(to: end)
    }
    context.strokePath()

    context.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.9))
    context.setLineWidth(lineWidth)
    for (start, end) in lines {
      context.move(to: start)
      context.addLine(to: end)
    }
    context.strokePath()
  }

  static func drawCrosshairDotCursor(in context: CGContext, at point: CGPoint, size: CGFloat) {
    let halfLen = size / 2
    let gap = size * 0.2
    let lineWidth = max(1.5, size / 16)

    context.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
    context.setLineWidth(lineWidth + 1)

    let lines: [(CGPoint, CGPoint)] = [
      (CGPoint(x: point.x - halfLen, y: point.y), CGPoint(x: point.x - gap, y: point.y)),
      (CGPoint(x: point.x + gap, y: point.y), CGPoint(x: point.x + halfLen, y: point.y)),
      (CGPoint(x: point.x, y: point.y - halfLen), CGPoint(x: point.x, y: point.y - gap)),
      (CGPoint(x: point.x, y: point.y + gap), CGPoint(x: point.x, y: point.y + halfLen)),
    ]

    for (start, end) in lines {
      context.move(to: start)
      context.addLine(to: end)
    }
    context.strokePath()

    context.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.9))
    context.setLineWidth(lineWidth)
    for (start, end) in lines {
      context.move(to: start)
      context.addLine(to: end)
    }
    context.strokePath()

    let dotRadius = size * 0.08
    let dotRect = CGRect(
      x: point.x - dotRadius,
      y: point.y - dotRadius,
      width: dotRadius * 2,
      height: dotRadius * 2
    )
    context.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
    context.fillEllipse(in: dotRect)
  }

  static func drawTargetCursor(in context: CGContext, at point: CGPoint, size: CGFloat) {
    let radius = size / 2
    let lineWidth = max(1.5, size / 14)
    let gap = size * 0.1

    let circleRect = CGRect(
      x: point.x - radius,
      y: point.y - radius,
      width: radius * 2,
      height: radius * 2
    )

    let lines: [(CGPoint, CGPoint)] = [
      (CGPoint(x: point.x - radius, y: point.y), CGPoint(x: point.x - gap, y: point.y)),
      (CGPoint(x: point.x + gap, y: point.y), CGPoint(x: point.x + radius, y: point.y)),
      (CGPoint(x: point.x, y: point.y - radius), CGPoint(x: point.x, y: point.y - gap)),
      (CGPoint(x: point.x, y: point.y + gap), CGPoint(x: point.x, y: point.y + radius)),
    ]

    context.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.95))
    context.setLineWidth(lineWidth + 1)
    context.strokeEllipse(in: circleRect)
    for (start, end) in lines {
      context.move(to: start)
      context.addLine(to: end)
    }
    context.strokePath()

    context.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.7))
    context.setLineWidth(lineWidth)
    context.strokeEllipse(in: circleRect)
    for (start, end) in lines {
      context.move(to: start)
      context.addLine(to: end)
    }
    context.strokePath()

    let dotR = size * 0.06
    let dotRect = CGRect(
      x: point.x - dotR,
      y: point.y - dotR,
      width: dotR * 2,
      height: dotR * 2
    )
    context.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
    context.fillEllipse(in: dotRect)
  }
}
