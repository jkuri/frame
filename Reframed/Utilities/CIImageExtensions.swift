import AppKit
import CoreImage
import SwiftUI

extension CIImage {
  func resized(to size: CGSize) -> CIImage {
    let scaleX = size.width / extent.width
    let scaleY = size.height / extent.height
    return transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
  }

  func resizedToFill(_ targetSize: CGSize) -> CIImage {
    let sourceAspect = extent.width / max(extent.height, 1)
    let targetAspect = targetSize.width / max(targetSize.height, 1)
    let scale: CGFloat
    if sourceAspect > targetAspect {
      scale = targetSize.height / max(extent.height, 1)
    } else {
      scale = targetSize.width / max(extent.width, 1)
    }
    let scaled = transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    let cropX = (scaled.extent.width - targetSize.width) / 2
    let cropY = (scaled.extent.height - targetSize.height) / 2
    return scaled.cropped(
      to: CGRect(x: scaled.extent.origin.x + cropX, y: scaled.extent.origin.y + cropY, width: targetSize.width, height: targetSize.height)
    )
  }

  static func renderGradientCIImage(presetId: Int, size: CGSize) -> CIImage? {
    guard let preset = GradientPresets.preset(for: presetId) else { return nil }
    let width = Int(size.width)
    let height = Int(size.height)
    guard width > 0, height > 0 else { return nil }

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard
      let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
      )
    else { return nil }

    let cgColors = preset.cgColors
    let locations: [CGFloat] = cgColors.enumerated().map { i, _ in
      CGFloat(i) / CGFloat(max(cgColors.count - 1, 1))
    }

    guard
      let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: cgColors as CFArray,
        locations: locations
      )
    else { return nil }

    let startPoint = CGPoint(x: size.width * preset.cgStartPoint.x, y: size.height * (1.0 - preset.cgStartPoint.y))
    let endPoint = CGPoint(x: size.width * preset.cgEndPoint.x, y: size.height * (1.0 - preset.cgEndPoint.y))

    context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

    guard let cgImage = context.makeImage() else { return nil }
    return CIImage(cgImage: cgImage)
  }
}
