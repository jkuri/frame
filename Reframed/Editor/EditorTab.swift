import Foundation

enum EditorTab: String, CaseIterable, Identifiable {
  case general, video, camera, audio, cursor, zoom, effects, captions

  var id: String { rawValue }

  var label: String {
    switch self {
    case .general: "General"
    case .video: "Video"
    case .camera: "Camera"
    case .audio: "Audio"
    case .cursor: "Cursor"
    case .zoom: "Zoom"
    case .effects: "Effects"
    case .captions: "Captions"
    }
  }

  var icon: String {
    switch self {
    case .general: "slider.horizontal.3"
    case .video: "play.rectangle"
    case .camera: "web.camera"
    case .audio: "speaker.wave.2"
    case .cursor: "cursorarrow"
    case .zoom: "plus.magnifyingglass"
    case .effects: "wand.and.stars"
    case .captions: "captions.bubble"
    }
  }

  static let isAppleSilicon: Bool = {
    var sysinfo = utsname()
    uname(&sysinfo)
    let machine = withUnsafePointer(to: &sysinfo.machine) {
      $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
    }
    return machine.hasPrefix("arm64")
  }()

  static var availableCases: [EditorTab] {
    if isAppleSilicon {
      return allCases
    }
    return allCases.filter { $0 != .captions }
  }
}
