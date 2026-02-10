import Foundation

extension FileManager {
  func tempRecordingURL() -> URL {
    let tempDir = temporaryDirectory.appendingPathComponent("Frame", isDirectory: true)
    try? createDirectory(at: tempDir, withIntermediateDirectories: true)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd-HHmmss"
    let filename = "frame-\(formatter.string(from: Date())).mp4"
    return tempDir.appendingPathComponent(filename)
  }

  @MainActor
  func defaultSaveDirectory() -> URL {
    let folderPath = ConfigService.shared.outputFolder
    let expanded = NSString(string: folderPath).expandingTildeInPath
    let url = URL(fileURLWithPath: expanded, isDirectory: true)
    try? createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }

  @MainActor
  func defaultSaveURL(for tempURL: URL) -> URL {
    defaultSaveDirectory().appendingPathComponent(tempURL.lastPathComponent)
  }

  func moveToFinal(from source: URL, to destination: URL) throws {
    if fileExists(atPath: destination.path) {
      try removeItem(at: destination)
    }
    try moveItem(at: source, to: destination)
  }
}
