import CoreGraphics

extension CursorRenderer {
  static func drawPointerCursor(in context: CGContext, at point: CGPoint, size: CGFloat) {
    let s = size / 24.0
    let path = pointerPath(at: point, scale: s)

    context.addPath(path)
    context.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
    context.fillPath()

    let x = point.x
    let y = point.y
    let knuckleLine = CGMutablePath()
    knuckleLine.move(to: CGPoint(x: x + 0.5 * s, y: y + 10 * s))
    knuckleLine.addLine(to: CGPoint(x: x + 6 * s, y: y + 10 * s))
    context.addPath(knuckleLine)
    context.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.12))
    context.setLineWidth(0.8 * s)
    context.strokePath()

    context.addPath(path)
    context.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.8))
    context.setLineWidth(1.2 * s)
    context.strokePath()
  }

  static func drawGoldPointerCursor(in context: CGContext, at point: CGPoint, size: CGFloat) {
    let s = size / 24.0
    let path = pointerPath(at: point, scale: s)

    context.addPath(path)
    context.setFillColor(CGColor(srgbRed: 1.0, green: 0.84, blue: 0.25, alpha: 1))
    context.fillPath()

    let x = point.x
    let y = point.y
    let knuckleLine = CGMutablePath()
    knuckleLine.move(to: CGPoint(x: x + 0.5 * s, y: y + 10 * s))
    knuckleLine.addLine(to: CGPoint(x: x + 6 * s, y: y + 10 * s))
    context.addPath(knuckleLine)
    context.setStrokeColor(CGColor(srgbRed: 0.6, green: 0.45, blue: 0.0, alpha: 0.2))
    context.setLineWidth(0.8 * s)
    context.strokePath()

    context.addPath(path)
    context.setStrokeColor(CGColor(srgbRed: 0.45, green: 0.35, blue: 0.0, alpha: 0.85))
    context.setLineWidth(1.2 * s)
    context.strokePath()
  }

  static func drawGrabCursor(in context: CGContext, at point: CGPoint, size: CGFloat) {
    let s = size / 24.0
    let cx = point.x
    let cy = point.y

    func pt(_ sx: CGFloat, _ sy: CGFloat) -> CGPoint {
      CGPoint(x: cx + (sx - 19) * s, y: cy + (sy - 20) * s)
    }

    let path = CGMutablePath()
    path.move(to: pt(29.61, 18))
    path.addCurve(to: pt(25.2, 32.2), control1: pt(29.3, 23), control2: pt(27, 29.5))
    path.addLine(to: pt(15.47, 32.2))
    path.addQuadCurve(to: pt(10.27, 26.48), control: pt(12, 30.5))
    path.addCurve(
      to: pt(7.79, 16.09),
      control1: pt(7.9, 22.62),
      control2: pt(7.27, 18.25)
    )
    path.addQuadCurve(to: pt(11, 12.76), control: pt(8.5, 13.5))
    path.addLine(to: pt(11, 20.41))
    path.addQuadCurve(to: pt(12.8, 20.41), control: pt(11.9, 21.3))
    path.addLine(to: pt(12.8, 9.89))
    path.addCurve(
      to: pt(14.26, 8.89),
      control1: pt(12.8, 9.42),
      control2: pt(13.39, 8.89)
    )
    path.addCurve(
      to: pt(15.75, 9.89),
      control1: pt(15.13, 8.89),
      control2: pt(15.75, 9.41)
    )
    path.addLine(to: pt(15.75, 15.61))
    path.addLine(to: pt(17.55, 15.61))
    path.addLine(to: pt(17.55, 8.81))
    path.addCurve(
      to: pt(19.01, 8.1),
      control1: pt(17.55, 8.53),
      control2: pt(18.13, 8.1)
    )
    path.addCurve(
      to: pt(20.54, 8.85),
      control1: pt(19.89, 8.1),
      control2: pt(20.54, 8.58)
    )
    path.addLine(to: pt(20.54, 15.74))
    path.addLine(to: pt(22.34, 15.74))
    path.addLine(to: pt(22.51, 9.88))
    path.addQuadCurve(to: pt(23.69, 9.56), control: pt(23, 9.3))
    path.addCurve(
      to: pt(25.19, 10.24),
      control1: pt(24.62, 9.56),
      control2: pt(25.19, 10.0)
    )
    path.addLine(to: pt(25.19, 16.74))
    path.addLine(to: pt(27, 16.74))
    path.addLine(to: pt(27, 11.87))
    path.addQuadCurve(to: pt(28.12, 11.54), control: pt(27.5, 11.2))
    path.addCurve(
      to: pt(29.64, 12.48),
      control1: pt(28.98, 11.54),
      control2: pt(29.64, 12.05)
    )
    path.closeSubpath()

    context.addPath(path)
    context.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
    context.fillPath()

    context.addPath(path)
    context.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.7))
    context.setLineWidth(1.0 * s)
    context.setLineJoin(.round)
    context.strokePath()
  }
}
