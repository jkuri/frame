import CoreGraphics

extension CursorRenderer {
  static func drawArrowCursor(in context: CGContext, at point: CGPoint, size: CGFloat) {
    let s = size / 24.0
    let path = arrowPath(at: point, scale: s)

    context.addPath(path)
    context.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
    context.fillPath()

    context.addPath(path)
    context.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.8))
    context.setLineWidth(1.5 * s)
    context.strokePath()
  }

  static func drawOutlineArrowCursor(in context: CGContext, at point: CGPoint, size: CGFloat) {
    let s = size / 24.0
    let path = arrowPath(at: point, scale: s)

    context.addPath(path)
    context.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
    context.setLineWidth(2.5 * s)
    context.strokePath()

    context.addPath(path)
    context.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.6))
    context.setLineWidth(1.2 * s)
    context.strokePath()
  }

  static func drawInvertedArrowCursor(in context: CGContext, at point: CGPoint, size: CGFloat) {
    let s = size / 24.0
    let path = arrowPath(at: point, scale: s)

    context.addPath(path)
    context.setFillColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.9))
    context.fillPath()

    context.addPath(path)
    context.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
    context.setLineWidth(1.5 * s)
    context.strokePath()
  }

  static func drawBlueArrowCursor(in context: CGContext, at point: CGPoint, size: CGFloat) {
    let s = size / 24.0
    let path = arrowPath(at: point, scale: s)

    context.addPath(path)
    context.setFillColor(CGColor(srgbRed: 0.23, green: 0.51, blue: 0.96, alpha: 1))
    context.fillPath()

    context.addPath(path)
    context.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.9))
    context.setLineWidth(1.5 * s)
    context.strokePath()
  }
}
