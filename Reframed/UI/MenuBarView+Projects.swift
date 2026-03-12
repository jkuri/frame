import AVFoundation
import SwiftUI

extension MenuBarView {
  func loadRecentProjects() async {
    let path = (ConfigService.shared.projectFolder as NSString).expandingTildeInPath
    let folderURL = URL(fileURLWithPath: path)
    let fm = FileManager.default

    guard
      let contents = try? fm.contentsOfDirectory(
        at: folderURL,
        includingPropertiesForKeys: [.contentModificationDateKey],
        options: [.skipsHiddenFiles]
      )
    else {
      recentProjects = []
      return
    }

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    var projects: [RecentProject] = []
    for url in contents where url.pathExtension == "frm" {
      let metadataURL = url.appendingPathComponent("project.json")
      guard let data = try? Data(contentsOf: metadataURL),
        let metadata = try? decoder.decode(ProjectMetadata.self, from: data)
      else { continue }

      let name = metadata.name ?? url.deletingPathExtension().lastPathComponent
      let screenURL = url.appendingPathComponent("screen.mp4")
      let asset = AVURLAsset(url: screenURL)
      let duration = try? await asset.load(.duration)
      let durationSeconds = duration.map { Int(CMTimeGetSeconds($0)) }

      let bundleSize = Self.directorySize(url: url, fm: fm)

      projects.append(
        RecentProject(
          url: url,
          name: name,
          createdAt: metadata.createdAt,
          captureMode: metadata.captureMode,
          hasWebcam: metadata.hasWebcam || metadata.webcamSize != nil,
          hasSystemAudio: metadata.hasSystemAudio,
          hasMicrophoneAudio: metadata.hasMicrophoneAudio,
          duration: durationSeconds.flatMap { $0 > 0 ? $0 : nil },
          fileSize: bundleSize
        )
      )
    }

    let sorted = projects.sorted { $0.createdAt > $1.createdAt }
    totalProjectCount = sorted.count
    recentProjects = sorted
  }

  static nonisolated func directorySize(url: URL, fm: FileManager) -> Int64? {
    guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
      return nil
    }
    var total: Int64 = 0
    for case let fileURL as URL in enumerator {
      if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
        total += Int64(size)
      }
    }
    return total
  }
}
