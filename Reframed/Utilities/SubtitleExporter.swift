import Foundation

enum SubtitleExporter {
  static func exportSRT(segments: [CaptionSegment], to url: URL) throws {
    var output = ""
    for (index, segment) in segments.enumerated() {
      output += "\(index + 1)\n"
      output += "\(srtTimestamp(segment.startSeconds)) --> \(srtTimestamp(segment.endSeconds))\n"
      output += "\(segment.text)\n\n"
    }
    try output.write(to: url, atomically: true, encoding: .utf8)
  }

  static func exportVTT(segments: [CaptionSegment], to url: URL) throws {
    var output = "WEBVTT\n\n"
    for segment in segments {
      output += "\(vttTimestamp(segment.startSeconds)) --> \(vttTimestamp(segment.endSeconds))\n"
      output += "\(segment.text)\n\n"
    }
    try output.write(to: url, atomically: true, encoding: .utf8)
  }

  private static func srtTimestamp(_ seconds: Double) -> String {
    let h = Int(seconds) / 3600
    let m = (Int(seconds) % 3600) / 60
    let s = Int(seconds) % 60
    let ms = Int((seconds.truncatingRemainder(dividingBy: 1)) * 1000)
    return String(format: "%02d:%02d:%02d,%03d", h, m, s, ms)
  }

  private static func vttTimestamp(_ seconds: Double) -> String {
    let h = Int(seconds) / 3600
    let m = (Int(seconds) % 3600) / 60
    let s = Int(seconds) % 60
    let ms = Int((seconds.truncatingRemainder(dividingBy: 1)) * 1000)
    return String(format: "%02d:%02d:%02d.%03d", h, m, s, ms)
  }
}
