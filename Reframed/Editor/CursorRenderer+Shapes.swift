import CoreGraphics

extension CursorRenderer {
  static func drawCircleDotCursor(in context: CGContext, at point: CGPoint, size: CGFloat) {
    let outerRadius = size / 2
    let innerRadius = size * 0.15
    let lineWidth = max(1.5, size / 12)

    let outerRect = CGRect(
      x: point.x - outerRadius,
      y: point.y - outerRadius,
      width: outerRadius * 2,
      height: outerRadius * 2
    )

    context.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.9))
    context.setLineWidth(lineWidth + 1)
    context.strokeEllipse(in: outerRect)

    context.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.7))
    context.setLineWidth(lineWidth)
    context.strokeEllipse(in: outerRect)

    let innerRect = CGRect(
      x: point.x - innerRadius,
      y: point.y - innerRadius,
      width: innerRadius * 2,
      height: innerRadius * 2
    )
    context.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
    context.fillEllipse(in: innerRect)
  }

  static func drawDotCursor(in context: CGContext, at point: CGPoint, size: CGFloat) {
    let radius = size * 0.35
    let dotRect = CGRect(
      x: point.x - radius,
      y: point.y - radius,
      width: radius * 2,
      height: radius * 2
    )

    context.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
    context.fillEllipse(in: dotRect)
    context.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.6))
    context.setLineWidth(max(1.0, size / 16))
    context.strokeEllipse(in: dotRect)
  }

  static func drawCircleCursor(in context: CGContext, at point: CGPoint, size: CGFloat) {
    let radius = size / 2
    let lineWidth = max(1.5, size / 10)
    let circleRect = CGRect(
      x: point.x - radius,
      y: point.y - radius,
      width: radius * 2,
      height: radius * 2
    )

    context.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.95))
    context.setLineWidth(lineWidth + 1)
    context.strokeEllipse(in: circleRect)

    context.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.7))
    context.setLineWidth(lineWidth)
    context.strokeEllipse(in: circleRect)
  }

  static func drawBullseyeCursor(in context: CGContext, at point: CGPoint, size: CGFloat) {
    let outerRadius = size / 2
    let midRadius = size * 0.3
    let innerRadius = size * 0.12
    let lineWidth = max(1.0, size / 16)

    let outerRect = CGRect(
      x: point.x - outerRadius,
      y: point.y - outerRadius,
      width: outerRadius * 2,
      height: outerRadius * 2
    )
    context.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.9))
    context.setLineWidth(lineWidth + 1)
    context.strokeEllipse(in: outerRect)
    context.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.7))
    context.setLineWidth(lineWidth)
    context.strokeEllipse(in: outerRect)

    let midRect = CGRect(
      x: point.x - midRadius,
      y: point.y - midRadius,
      width: midRadius * 2,
      height: midRadius * 2
    )
    context.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.9))
    context.setLineWidth(lineWidth + 1)
    context.strokeEllipse(in: midRect)
    context.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.7))
    context.setLineWidth(lineWidth)
    context.strokeEllipse(in: midRect)

    let innerRect = CGRect(
      x: point.x - innerRadius,
      y: point.y - innerRadius,
      width: innerRadius * 2,
      height: innerRadius * 2
    )
    context.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
    context.fillEllipse(in: innerRect)
  }

  static func drawDiamondCursor(in context: CGContext, at point: CGPoint, size: CGFloat) {
    let half = size / 2
    let lineWidth = max(1.5, size / 14)

    let path = CGMutablePath()
    path.move(to: CGPoint(x: point.x, y: point.y - half))
    path.addLine(to: CGPoint(x: point.x + half, y: point.y))
    path.addLine(to: CGPoint(x: point.x, y: point.y + half))
    path.addLine(to: CGPoint(x: point.x - half, y: point.y))
    path.closeSubpath()

    context.addPath(path)
    context.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.15))
    context.fillPath()

    context.addPath(path)
    context.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
    context.setLineWidth(lineWidth + 1)
    context.strokePath()

    context.addPath(path)
    context.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.7))
    context.setLineWidth(lineWidth)
    context.strokePath()
  }

  static func drawPlusCursor(in context: CGContext, at point: CGPoint, size: CGFloat) {
    let halfLen = size / 2
    let thickness = max(2.0, size / 6)

    let hRect = CGRect(
      x: point.x - halfLen,
      y: point.y - thickness / 2,
      width: size,
      height: thickness
    )
    let vRect = CGRect(
      x: point.x - thickness / 2,
      y: point.y - halfLen,
      width: thickness,
      height: size
    )

    let plusPath = CGMutablePath()
    plusPath.addRect(hRect)
    plusPath.addRect(vRect)

    context.addPath(plusPath)
    context.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
    context.fillPath()

    context.addPath(plusPath)
    context.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.6))
    context.setLineWidth(max(1.0, size / 20))
    context.strokePath()
  }

  static func drawSpotlightCursor(in context: CGContext, at point: CGPoint, size: CGFloat) {
    let radius = size / 2
    let circleRect = CGRect(
      x: point.x - radius,
      y: point.y - radius,
      width: radius * 2,
      height: radius * 2
    )

    context.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.3))
    context.fillEllipse(in: circleRect)

    context.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.9))
    context.setLineWidth(max(1.5, size / 12))
    context.strokeEllipse(in: circleRect)
  }
}
