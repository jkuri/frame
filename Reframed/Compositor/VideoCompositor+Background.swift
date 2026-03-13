import CoreGraphics
import Foundation
import ImageIO

extension VideoCompositor {
  static func backgroundColorTuples(
    for style: BackgroundStyle
  ) -> [(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)] {
    switch style {
    case .none:
      return []
    case .gradient(let id):
      guard let preset = GradientPresets.preset(for: id) else { return [] }
      return preset.cgColors.map { color in
        let components = color.components ?? [0, 0, 0, 1]
        if components.count >= 4 {
          return (r: components[0], g: components[1], b: components[2], a: components[3])
        } else if components.count >= 2 {
          return (r: components[0], g: components[0], b: components[0], a: components[1])
        }
        return (r: 0, g: 0, b: 0, a: 1)
      }
    case .solidColor(let color):
      return [(r: color.r, g: color.g, b: color.b, a: color.a)]
    case .image:
      return []
    }
  }

  static func loadBackgroundImage(style: BackgroundStyle, imageURL: URL?) -> CGImage? {
    guard case .image = style, let imageURL = imageURL,
      let dataProvider = CGDataProvider(url: imageURL as CFURL),
      let source = CGImageSourceCreateWithDataProvider(dataProvider, nil),
      CGImageSourceGetCount(source) > 0
    else { return nil }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
  }

  static func loadCameraBackgroundImage(style: CameraBackgroundStyle, imageURL: URL?) -> CGImage? {
    guard case .image = style, let imageURL = imageURL,
      let dataProvider = CGDataProvider(url: imageURL as CFURL),
      let source = CGImageSourceCreateWithDataProvider(dataProvider, nil),
      CGImageSourceGetCount(source) > 0
    else { return nil }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
  }
}
