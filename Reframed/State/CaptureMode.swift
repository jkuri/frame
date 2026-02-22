enum CaptureMode: String, Sendable, Equatable, Codable {
  case none = "none"
  case entireScreen = "entireScreen"
  case selectedWindow = "selectedWindow"
  case selectedArea = "selectedArea"
  case device = "device"

  static func cameraMaxDimensions(for resolution: String) -> (Int, Int) {
    switch resolution {
    case "720p":
      return (1280, 720)
    case "4K":
      return (3840, 2160)
    default:
      return (1920, 1080)
    }
  }
}
