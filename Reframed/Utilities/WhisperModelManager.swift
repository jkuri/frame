import Foundation
import WhisperKit

enum WhisperModel: String, CaseIterable, Identifiable, Sendable {
  case base = "openai_whisper-base"
  case small = "openai_whisper-small"
  case medium = "openai_whisper-medium"
  case large = "openai_whisper-large-v3"

  var id: String { rawValue }

  var label: String {
    switch self {
    case .base: "Base (~140 MB)"
    case .small: "Small (~460 MB)"
    case .medium: "Medium (~1.5 GB)"
    case .large: "Large (~3 GB)"
    }
  }

  var shortLabel: String {
    switch self {
    case .base: "Base"
    case .small: "Small"
    case .medium: "Medium"
    case .large: "Large"
    }
  }

  var description: String {
    switch self {
    case .base: "Fast, lower accuracy. Good for clear English audio."
    case .small: "Balanced speed and accuracy. Good for most use cases."
    case .medium: "High accuracy, slower. Recommended for multilingual."
    case .large: "Best accuracy, slowest. Best for difficult audio."
    }
  }
}

@MainActor
@Observable
final class WhisperModelManager {
  static let shared = WhisperModelManager()

  var downloadedModels: Set<String> = []
  var isDownloading = false
  var downloadProgress: Double = 0
  var downloadingModel: WhisperModel?

  private var modelPaths: [String: URL] = [:]
  private var downloadTask: Task<Void, Never>?
  private let modelsDirectory: URL

  private init() {
    let base = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(".reframed")
    self.modelsDirectory = base
    try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    scanDownloadedModels()
  }

  func scanDownloadedModels() {
    downloadedModels.removeAll()
    modelPaths.removeAll()
    let fm = FileManager.default
    guard
      let enumerator = fm.enumerator(
        at: modelsDirectory,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles]
      )
    else { return }
    while let url = enumerator.nextObject() as? URL {
      let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
      guard isDir else { continue }
      let name = url.lastPathComponent
      if WhisperModel(rawValue: name) != nil {
        let configFile = url.appendingPathComponent("config.json")
        if fm.fileExists(atPath: configFile.path) {
          downloadedModels.insert(name)
          modelPaths[name] = url
        }
      }
    }
  }

  func isDownloaded(_ model: WhisperModel) -> Bool {
    downloadedModels.contains(model.rawValue)
  }

  func modelPath(for model: WhisperModel) -> URL? {
    modelPaths[model.rawValue]
  }

  func downloadModel(
    _ model: WhisperModel,
    onProgress: (@MainActor @Sendable (Double) -> Void)? = nil
  ) async throws {
    isDownloading = true
    downloadProgress = 0
    downloadingModel = model
    defer {
      isDownloading = false
      downloadingModel = nil
    }

    let mgr = self
    let callback: @Sendable (Progress) -> Void = { progress in
      Task { @MainActor in
        mgr.downloadProgress = progress.fractionCompleted
        onProgress?(progress.fractionCompleted)
      }
    }
    let modelFolder = try await WhisperKit.download(
      variant: model.rawValue,
      downloadBase: modelsDirectory,
      progressCallback: callback
    )

    modelPaths[model.rawValue] = modelFolder
    downloadedModels.insert(model.rawValue)
    downloadProgress = 1.0
    onProgress?(1.0)
  }

  func deleteModel(_ model: WhisperModel) {
    guard let path = modelPaths[model.rawValue] else { return }
    try? FileManager.default.removeItem(at: path)
    downloadedModels.remove(model.rawValue)
    modelPaths.removeValue(forKey: model.rawValue)
  }

  func cancelDownload() {
    downloadTask?.cancel()
    downloadTask = nil
    isDownloading = false
    downloadingModel = nil
    downloadProgress = 0
  }
}
