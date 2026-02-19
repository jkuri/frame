import AVFoundation
import Foundation

struct MediaFileInfo: Sendable {
  let fileSize: String
  let bitrate: String?
  let fps: String?

  static func load(url: URL) async -> MediaFileInfo {
    let size = formattedFileSize(url: url)
    let asset = AVURLAsset(url: url)

    var bitrate: String?
    var fps: String?

    if let tracks = try? await asset.loadTracks(withMediaType: .video),
      let track = tracks.first
    {
      if let rate = try? await track.load(.nominalFrameRate), rate > 0 {
        fps = "\(Int(rate.rounded()))"
      }
      if let bps = try? await track.load(.estimatedDataRate), bps > 0 {
        bitrate = formatBitrate(bps)
      }
    }

    if bitrate == nil,
      let tracks = try? await asset.loadTracks(withMediaType: .audio),
      let track = tracks.first
    {
      if let bps = try? await track.load(.estimatedDataRate), bps > 0 {
        bitrate = formatBitrate(bps)
      }
    }

    return MediaFileInfo(fileSize: size, bitrate: bitrate, fps: fps)
  }

  private static func formattedFileSize(url: URL) -> String {
    guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
      let size = attrs[.size] as? Int64
    else {
      return "—"
    }
    return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
  }

  private static func formatBitrate(_ bps: Float) -> String {
    let kbps = Int(bps / 1000)
    if kbps >= 1000 {
      let mbps = Double(kbps) / 1000.0
      return String(format: "%.1f Mbps", mbps)
    }
    return "\(kbps) kbps"
  }
}
