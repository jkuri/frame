import AppKit
import CoreGraphics
import QuartzCore

final class SpotlightOverlayLayer: CALayer {
  private var currentPosition: CGPoint = .zero
  private var currentRadius: CGFloat = 200
  private var currentDimOpacity: CGFloat = 0.6
  private var currentEdgeSoftness: CGFloat = 50
  private var currentContainerSize: CGSize = .zero
  private var isVisible = false

  override init() {
    super.init()
    isOpaque = false
    contentsGravity = .resize
  }

  override init(layer: Any) {
    super.init(layer: layer)
    if let other = layer as? SpotlightOverlayLayer {
      currentPosition = other.currentPosition
      currentRadius = other.currentRadius
      currentDimOpacity = other.currentDimOpacity
      currentEdgeSoftness = other.currentEdgeSoftness
      currentContainerSize = other.currentContainerSize
      isVisible = other.isVisible
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  func update(
    pixelPosition: CGPoint,
    radius: CGFloat,
    dimOpacity: CGFloat,
    edgeSoftness: CGFloat,
    visible: Bool,
    containerSize: CGSize
  ) {
    let needsRedraw =
      currentPosition != pixelPosition
      || currentRadius != radius
      || currentDimOpacity != dimOpacity
      || currentEdgeSoftness != edgeSoftness
      || currentContainerSize != containerSize
      || isVisible != visible

    currentPosition = pixelPosition
    currentRadius = radius
    currentDimOpacity = dimOpacity
    currentEdgeSoftness = edgeSoftness
    currentContainerSize = containerSize
    isVisible = visible

    CATransaction.begin()
    CATransaction.setDisableActions(true)
    frame = CGRect(origin: .zero, size: containerSize)
    CATransaction.commit()

    if needsRedraw {
      renderSpotlight()
    }
  }

  private func renderSpotlight() {
    guard isVisible, currentContainerSize.width > 0, currentContainerSize.height > 0 else {
      contents = nil
      return
    }

    let w = Int(currentContainerSize.width)
    let h = Int(currentContainerSize.height)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard
      let ctx = CGContext(
        data: nil,
        width: w,
        height: h,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    else { return }

    let center = CGPoint(x: currentPosition.x, y: currentPosition.y)
    let dimColor = CGColor(red: 0, green: 0, blue: 0, alpha: currentDimOpacity)
    let bounds = CGRect(x: 0, y: 0, width: w, height: h)

    if currentEdgeSoftness <= 0 {
      let path = CGMutablePath()
      path.addRect(bounds)
      path.addEllipse(
        in: CGRect(
          x: center.x - currentRadius,
          y: center.y - currentRadius,
          width: currentRadius * 2,
          height: currentRadius * 2
        )
      )
      ctx.addPath(path)
      ctx.clip(using: .evenOdd)
      ctx.setFillColor(dimColor)
      ctx.fill(bounds)
    } else {
      let outerRadius = currentRadius
      let innerFrac: CGFloat = outerRadius > 0 ? max(0, (outerRadius - currentEdgeSoftness) / outerRadius) : 0
      let clearColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0)

      let locations: [CGFloat] = [0, innerFrac, 1]
      guard
        let gradient = CGGradient(
          colorsSpace: colorSpace,
          colors: [clearColor, clearColor, dimColor] as CFArray,
          locations: locations
        )
      else { return }

      ctx.drawRadialGradient(
        gradient,
        startCenter: center,
        startRadius: 0,
        endCenter: center,
        endRadius: outerRadius,
        options: [.drawsAfterEndLocation]
      )
    }

    contents = ctx.makeImage()
  }
}
