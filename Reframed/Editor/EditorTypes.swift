import Foundation

enum CanvasAspect: String, Codable, Sendable, CaseIterable, Identifiable {
  case original
  case ratio16x9
  case ratio1x1
  case ratio4x3
  case ratio9x16

  var id: String { rawValue }

  var label: String {
    switch self {
    case .original: "Original"
    case .ratio16x9: "16:9"
    case .ratio1x1: "1:1"
    case .ratio4x3: "4:3"
    case .ratio9x16: "9:16"
    }
  }

  func size(for screenSize: CGSize) -> CGSize? {
    switch self {
    case .original: nil
    case .ratio16x9: CGSize(width: screenSize.width, height: screenSize.width * 9.0 / 16.0)
    case .ratio1x1: CGSize(width: screenSize.width, height: screenSize.width)
    case .ratio4x3: CGSize(width: screenSize.width, height: screenSize.width * 3.0 / 4.0)
    case .ratio9x16: CGSize(width: screenSize.height * 9.0 / 16.0, height: screenSize.height)
    }
  }
}

enum CameraAspect: String, Codable, Sendable, CaseIterable, Identifiable {
  case original
  case ratio16x9
  case ratio1x1
  case ratio4x3
  case ratio9x16

  var id: String { rawValue }

  var label: String {
    switch self {
    case .original: "Original"
    case .ratio16x9: "16:9"
    case .ratio1x1: "1:1"
    case .ratio4x3: "4:3"
    case .ratio9x16: "9:16"
    }
  }

  func heightToWidthRatio(webcamSize: CGSize) -> CGFloat {
    switch self {
    case .original: webcamSize.height / max(webcamSize.width, 1)
    case .ratio16x9: 9.0 / 16.0
    case .ratio1x1: 1.0
    case .ratio4x3: 3.0 / 4.0
    case .ratio9x16: 16.0 / 9.0
    }
  }
}

enum CameraFullscreenFillMode: String, Codable, Sendable, CaseIterable, Identifiable {
  case fill, fit

  var id: String { rawValue }

  var label: String {
    switch self {
    case .fill: "Fill"
    case .fit: "Fit"
    }
  }
}

enum CameraFullscreenAspect: String, Codable, Sendable, CaseIterable, Identifiable {
  case original
  case ratio16x9
  case ratio1x1
  case ratio4x3
  case ratio9x16

  var id: String { rawValue }

  var label: String {
    switch self {
    case .original: "Original"
    case .ratio16x9: "16:9"
    case .ratio1x1: "1:1"
    case .ratio4x3: "4:3"
    case .ratio9x16: "9:16"
    }
  }

  func aspectRatio(webcamSize: CGSize) -> CGFloat {
    switch self {
    case .original: webcamSize.width / max(webcamSize.height, 1)
    case .ratio16x9: 16.0 / 9.0
    case .ratio1x1: 1.0
    case .ratio4x3: 4.0 / 3.0
    case .ratio9x16: 9.0 / 16.0
    }
  }
}

enum AudioTrackType {
  case system, mic
}

enum CameraCorner {
  case topLeft, topRight, bottomLeft, bottomRight
}
