import AVFoundation
import Foundation

struct ExportSettings: Sendable {
  var fps: ExportFPS = .original
  var resolution: ExportResolution = .original
  var codec: ExportCodec = .h264
}

enum ExportFPS: Sendable, CaseIterable, Identifiable {
  case original
  case fps24
  case fps30
  case fps60

  var id: Self { self }

  var label: String {
    switch self {
    case .original: "Original"
    case .fps24: "24 fps"
    case .fps30: "30 fps"
    case .fps60: "60 fps"
    }
  }

  func value(fallback: Int) -> Int {
    switch self {
    case .original: fallback
    case .fps24: 24
    case .fps30: 30
    case .fps60: 60
    }
  }

  var numericValue: Int? {
    switch self {
    case .original: nil
    case .fps24: 24
    case .fps30: 30
    case .fps60: 60
    }
  }
}

enum ExportResolution: Sendable, CaseIterable, Identifiable {
  case original
  case uhd4k
  case fhd1080
  case hd720

  var id: Self { self }

  var label: String {
    switch self {
    case .original: "Original"
    case .uhd4k: "4K"
    case .fhd1080: "1080p"
    case .hd720: "720p"
    }
  }

  var pixelWidth: CGFloat? {
    switch self {
    case .original: nil
    case .uhd4k: 3840
    case .fhd1080: 1920
    case .hd720: 1280
    }
  }
}

enum ExportCodec: Sendable, CaseIterable, Identifiable {
  case h264
  case h265

  var id: Self { self }

  var label: String {
    switch self {
    case .h264: "H.264"
    case .h265: "H.265 (HEVC)"
    }
  }

  var exportPreset: String {
    switch self {
    case .h264: AVAssetExportPresetHighestQuality
    case .h265: AVAssetExportPresetHEVCHighestQuality
    }
  }
}
