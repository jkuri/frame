import AppKit
import CoreGraphics
import Foundation

enum CursorStyle: Int, Codable, Sendable, CaseIterable {
  case defaultArrow = 0
  case crosshair = 1
  case circleDot = 2
  case outlineArrow = 3
  case dot = 4
  case circle = 5
  case bullseye = 6
  case diamond = 7
  case plus = 8
  case spotlight = 9
  case crosshairDot = 10
  case invertedArrow = 11
  case pointer = 12
  case grab = 13
  case pencil = 14
  case pen = 15
  case blueArrow = 16
  case goldPointer = 17
  case target = 18
  case marker = 19

  var label: String {
    switch self {
    case .defaultArrow: "Arrow"
    case .crosshair: "Crosshair"
    case .circleDot: "Ring Dot"
    case .outlineArrow: "Outline"
    case .dot: "Dot"
    case .circle: "Circle"
    case .bullseye: "Bullseye"
    case .diamond: "Diamond"
    case .plus: "Plus"
    case .spotlight: "Spotlight"
    case .crosshairDot: "Cross Dot"
    case .invertedArrow: "Inverted"
    case .pointer: "Pointer"
    case .grab: "Grab"
    case .pencil: "Pencil"
    case .pen: "Pen"
    case .blueArrow: "Blue Arrow"
    case .goldPointer: "Gold Hand"
    case .target: "Target"
    case .marker: "Marker"
    }
  }

  var isCentered: Bool {
    switch self {
    case .defaultArrow, .outlineArrow, .invertedArrow,
      .pointer, .pencil, .pen, .blueArrow, .goldPointer, .marker:
      false
    default: true
    }
  }
}

enum CursorRenderer {
  static func drawCursor(
    in context: CGContext,
    position: CGPoint,
    style: CursorStyle,
    size: CGFloat,
    scale: CGFloat = 1.0
  ) {
    let s = size * scale
    context.saveGState()

    switch style {
    case .defaultArrow:
      drawArrowCursor(in: context, at: position, size: s)
    case .crosshair:
      drawCrosshairCursor(in: context, at: position, size: s)
    case .circleDot:
      drawCircleDotCursor(in: context, at: position, size: s)
    case .outlineArrow:
      drawOutlineArrowCursor(in: context, at: position, size: s)
    case .dot:
      drawDotCursor(in: context, at: position, size: s)
    case .circle:
      drawCircleCursor(in: context, at: position, size: s)
    case .bullseye:
      drawBullseyeCursor(in: context, at: position, size: s)
    case .diamond:
      drawDiamondCursor(in: context, at: position, size: s)
    case .plus:
      drawPlusCursor(in: context, at: position, size: s)
    case .spotlight:
      drawSpotlightCursor(in: context, at: position, size: s)
    case .crosshairDot:
      drawCrosshairDotCursor(in: context, at: position, size: s)
    case .invertedArrow:
      drawInvertedArrowCursor(in: context, at: position, size: s)
    case .pointer:
      drawPointerCursor(in: context, at: position, size: s)
    case .grab:
      drawGrabCursor(in: context, at: position, size: s)
    case .pencil:
      drawPencilCursor(in: context, at: position, size: s)
    case .pen:
      drawPenCursor(in: context, at: position, size: s)
    case .blueArrow:
      drawBlueArrowCursor(in: context, at: position, size: s)
    case .goldPointer:
      drawGoldPointerCursor(in: context, at: position, size: s)
    case .target:
      drawTargetCursor(in: context, at: position, size: s)
    case .marker:
      drawMarkerCursor(in: context, at: position, size: s)
    }

    context.restoreGState()
  }

  static func drawClickHighlight(
    in context: CGContext,
    position: CGPoint,
    progress: Double,
    size: CGFloat,
    scale: CGFloat = 1.0,
    color: CGColor? = nil
  ) {
    let baseSize = size * scale
    let startDiameter = baseSize * 0.5
    let endDiameter = baseSize * 2.0
    let currentDiameter = startDiameter + (endDiameter - startDiameter) * CGFloat(progress)
    let opacity = CGFloat(1.0 - progress)

    let radius = currentDiameter / 2
    let circleRect = CGRect(
      x: position.x - radius,
      y: position.y - radius,
      width: currentDiameter,
      height: currentDiameter
    )

    let components = color?.components ?? [0.2, 0.5, 1.0, 1.0]
    let r = components.count > 0 ? components[0] : 0.2
    let g = components.count > 1 ? components[1] : 0.5
    let b = components.count > 2 ? components[2] : 1.0

    context.saveGState()
    context.setFillColor(CGColor(srgbRed: r, green: g, blue: b, alpha: 0.25 * opacity))
    context.fillEllipse(in: circleRect)
    context.setStrokeColor(CGColor(srgbRed: r, green: g, blue: b, alpha: 0.7 * opacity))
    context.setLineWidth(2.0 * scale)
    context.strokeEllipse(in: circleRect)
    context.restoreGState()
  }

  static func arrowPath(at point: CGPoint, scale s: CGFloat) -> CGMutablePath {
    let x = point.x
    let y = point.y
    let path = CGMutablePath()
    path.move(to: CGPoint(x: x, y: y))
    path.addLine(to: CGPoint(x: x, y: y + 20 * s))
    path.addLine(to: CGPoint(x: x + 5.5 * s, y: y + 15.5 * s))
    path.addLine(to: CGPoint(x: x + 9 * s, y: y + 22 * s))
    path.addLine(to: CGPoint(x: x + 12 * s, y: y + 20.5 * s))
    path.addLine(to: CGPoint(x: x + 8.5 * s, y: y + 13.5 * s))
    path.addLine(to: CGPoint(x: x + 15 * s, y: y + 13.5 * s))
    path.closeSubpath()
    return path
  }

  static func pointerPath(at point: CGPoint, scale s: CGFloat) -> CGMutablePath {
    let x = point.x
    let y = point.y
    let path = CGMutablePath()

    path.move(to: CGPoint(x: x + 2 * s, y: y + 1.5 * s))
    path.addQuadCurve(
      to: CGPoint(x: x + 6 * s, y: y + 1.5 * s),
      control: CGPoint(x: x + 4 * s, y: y - 1 * s)
    )

    path.addLine(to: CGPoint(x: x + 6 * s, y: y + 10 * s))

    path.addQuadCurve(
      to: CGPoint(x: x + 9 * s, y: y + 11.5 * s),
      control: CGPoint(x: x + 8 * s, y: y + 9 * s)
    )
    path.addQuadCurve(
      to: CGPoint(x: x + 11.5 * s, y: y + 13 * s),
      control: CGPoint(x: x + 10.5 * s, y: y + 10.5 * s)
    )

    path.addLine(to: CGPoint(x: x + 12 * s, y: y + 17 * s))
    path.addQuadCurve(
      to: CGPoint(x: x + 10 * s, y: y + 21 * s),
      control: CGPoint(x: x + 12 * s, y: y + 20 * s)
    )

    path.addLine(to: CGPoint(x: x + 2 * s, y: y + 21 * s))
    path.addQuadCurve(
      to: CGPoint(x: x + 0.5 * s, y: y + 17 * s),
      control: CGPoint(x: x + 0.5 * s, y: y + 20 * s)
    )

    path.addLine(to: CGPoint(x: x + 0.5 * s, y: y + 10 * s))
    path.addLine(to: CGPoint(x: x + 2 * s, y: y + 1.5 * s))
    path.closeSubpath()
    return path
  }
}
