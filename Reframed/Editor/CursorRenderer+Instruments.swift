import AppKit
import CoreGraphics

extension CursorRenderer {
  static func drawPencilCursor(in context: CGContext, at point: CGPoint, size: CGFloat) {
    let s = size / 24.0
    let x = point.x
    let y = point.y
    let c: CGFloat = 0.707

    let outline = CGMutablePath()
    outline.move(to: CGPoint(x: x, y: y))
    outline.addLine(to: CGPoint(x: x + 6 * c * s, y: y + 2 * c * s))
    outline.addLine(to: CGPoint(x: x + 20 * c * s, y: y + 16 * c * s))
    outline.addLine(to: CGPoint(x: x + 23 * c * s, y: y + 19 * c * s))
    outline.addLine(to: CGPoint(x: x + 19 * c * s, y: y + 23 * c * s))
    outline.addLine(to: CGPoint(x: x + 16 * c * s, y: y + 20 * c * s))
    outline.addLine(to: CGPoint(x: x + 2 * c * s, y: y + 6 * c * s))
    outline.closeSubpath()

    context.addPath(outline)
    context.setFillColor(CGColor(srgbRed: 1, green: 0.84, blue: 0.25, alpha: 1))
    context.fillPath()

    let tipPath = CGMutablePath()
    tipPath.move(to: CGPoint(x: x, y: y))
    tipPath.addLine(to: CGPoint(x: x + 6 * c * s, y: y + 2 * c * s))
    tipPath.addLine(to: CGPoint(x: x + 2 * c * s, y: y + 6 * c * s))
    tipPath.closeSubpath()
    context.addPath(tipPath)
    context.setFillColor(CGColor(srgbRed: 0.35, green: 0.35, blue: 0.35, alpha: 1))
    context.fillPath()

    let eraserPath = CGMutablePath()
    eraserPath.move(to: CGPoint(x: x + 20 * c * s, y: y + 16 * c * s))
    eraserPath.addLine(to: CGPoint(x: x + 23 * c * s, y: y + 19 * c * s))
    eraserPath.addLine(to: CGPoint(x: x + 19 * c * s, y: y + 23 * c * s))
    eraserPath.addLine(to: CGPoint(x: x + 16 * c * s, y: y + 20 * c * s))
    eraserPath.closeSubpath()
    context.addPath(eraserPath)
    context.setFillColor(CGColor(srgbRed: 0.95, green: 0.55, blue: 0.55, alpha: 1))
    context.fillPath()

    context.addPath(outline)
    context.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.7))
    context.setLineWidth(1.0 * s)
    context.strokePath()
  }

  static func drawPenCursor(in context: CGContext, at point: CGPoint, size: CGFloat) {
    let s = size / 24.0
    let x = point.x
    let y = point.y
    let c: CGFloat = 0.707

    let outline = CGMutablePath()
    outline.move(to: CGPoint(x: x, y: y))
    outline.addLine(to: CGPoint(x: x + 6.5 * c * s, y: y + 3.5 * c * s))
    outline.addLine(to: CGPoint(x: x + 21.5 * c * s, y: y + 18.5 * c * s))
    outline.addLine(to: CGPoint(x: x + 18.5 * c * s, y: y + 21.5 * c * s))
    outline.addLine(to: CGPoint(x: x + 3.5 * c * s, y: y + 6.5 * c * s))
    outline.closeSubpath()

    context.addPath(outline)
    context.setFillColor(CGColor(srgbRed: 0.2, green: 0.2, blue: 0.35, alpha: 1))
    context.fillPath()

    let nibPath = CGMutablePath()
    nibPath.move(to: CGPoint(x: x, y: y))
    nibPath.addLine(to: CGPoint(x: x + 6.5 * c * s, y: y + 3.5 * c * s))
    nibPath.addLine(to: CGPoint(x: x + 3.5 * c * s, y: y + 6.5 * c * s))
    nibPath.closeSubpath()
    context.addPath(nibPath)
    context.setFillColor(CGColor(srgbRed: 0.7, green: 0.7, blue: 0.75, alpha: 1))
    context.fillPath()

    context.addPath(outline)
    context.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.7))
    context.setLineWidth(1.0 * s)
    context.strokePath()
  }

  static func drawMarkerCursor(in context: CGContext, at point: CGPoint, size: CGFloat) {
    let s = size / 24.0
    let x = point.x
    let y = point.y
    let c: CGFloat = 0.707

    let tw: CGFloat = 5
    let bl: CGFloat = 15
    let capL: CGFloat = 3

    let outline = CGMutablePath()
    outline.move(to: CGPoint(x: x, y: y))
    outline.addLine(to: CGPoint(x: x + tw * c * s, y: y - tw * c * s))
    outline.addLine(to: CGPoint(x: x + (tw + bl) * c * s, y: y + (bl - tw) * c * s))
    outline.addLine(to: CGPoint(x: x + (tw + bl + capL) * c * s, y: y + (bl + capL - tw) * c * s))
    outline.addLine(to: CGPoint(x: x + (bl + capL) * c * s, y: y + (bl + capL) * c * s))
    outline.addLine(to: CGPoint(x: x + bl * c * s, y: y + bl * c * s))
    outline.closeSubpath()

    context.addPath(outline)
    context.setFillColor(CGColor(srgbRed: 0.18, green: 0.8, blue: 0.44, alpha: 1))
    context.fillPath()

    let capPath = CGMutablePath()
    capPath.move(to: CGPoint(x: x + (tw + bl) * c * s, y: y + (bl - tw) * c * s))
    capPath.addLine(to: CGPoint(x: x + (tw + bl + capL) * c * s, y: y + (bl + capL - tw) * c * s))
    capPath.addLine(to: CGPoint(x: x + (bl + capL) * c * s, y: y + (bl + capL) * c * s))
    capPath.addLine(to: CGPoint(x: x + bl * c * s, y: y + bl * c * s))
    capPath.closeSubpath()
    context.addPath(capPath)
    context.setFillColor(CGColor(srgbRed: 0.12, green: 0.55, blue: 0.30, alpha: 1))
    context.fillPath()

    context.addPath(outline)
    context.setStrokeColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.7))
    context.setLineWidth(1.0 * s)
    context.strokePath()
  }

  @MainActor static func previewImage(for style: CursorStyle, size: CGFloat) -> NSImage {
    let scale = NSScreen.main?.backingScaleFactor ?? 2.0
    let imgSize = size
    let pixelW = Int(imgSize * scale)
    let pixelH = Int(imgSize * scale)

    let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
    guard
      let ctx = CGContext(
        data: nil,
        width: pixelW,
        height: pixelH,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: bitmapInfo
      )
    else {
      return NSImage(size: NSSize(width: imgSize, height: imgSize))
    }

    ctx.clear(CGRect(x: 0, y: 0, width: pixelW, height: pixelH))
    ctx.translateBy(x: 0, y: CGFloat(pixelH))
    ctx.scaleBy(x: 1, y: -1)

    let cursorDrawSize = imgSize * scale * 0.55
    let drawPoint: CGPoint
    if style.isCentered {
      drawPoint = CGPoint(x: CGFloat(pixelW) / 2, y: CGFloat(pixelH) / 2)
    } else {
      let offsetX = CGFloat(pixelW) * 0.22
      let offsetY = CGFloat(pixelH) * 0.12
      drawPoint = CGPoint(x: offsetX, y: offsetY)
    }

    drawCursor(in: ctx, position: drawPoint, style: style, size: cursorDrawSize, scale: 1.0)

    guard let cgImage = ctx.makeImage() else {
      return NSImage(size: NSSize(width: imgSize, height: imgSize))
    }

    return NSImage(cgImage: cgImage, size: NSSize(width: imgSize, height: imgSize))
  }
}
