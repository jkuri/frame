import AppKit
import AVFoundation
import CoreMedia
import Foundation
import Logging

@MainActor
@Observable
final class EditorState {
  let result: RecordingResult
  var playerController: SyncedPlayerController
  var pipLayout = PiPLayout()
  var trimStart: CMTime = .zero
  var trimEnd: CMTime = .zero
  var isExporting = false
  var exportProgress: Double = 0

  var backgroundStyle: BackgroundStyle = .none
  var padding: CGFloat = 0
  var videoCornerRadius: CGFloat = 0
  var showExportSheet = false
  var showDeleteConfirmation = false
  var showExportResult = false
  var exportResultMessage = ""
  var exportResultIsError = false

  private let logger = Logger(label: "eu.jankuri.frame.editor-state")

  var isPlaying: Bool { playerController.isPlaying }
  var currentTime: CMTime { playerController.currentTime }
  var duration: CMTime { playerController.duration }
  var hasWebcam: Bool { result.webcamVideoURL != nil }

  init(result: RecordingResult) {
    self.result = result
    self.playerController = SyncedPlayerController(result: result)
  }

  func setup() async {
    await playerController.loadDuration()
    trimEnd = playerController.duration
    playerController.trimEnd = trimEnd
    playerController.setupTimeObserver()
    if hasWebcam {
      setPipCorner(.bottomRight)
    }
  }

  func play() { playerController.play() }
  func pause() { playerController.pause() }

  func seek(to time: CMTime) {
    playerController.seek(to: time)
  }

  func updateTrimStart(_ time: CMTime) {
    trimStart = time
  }

  func updateTrimEnd(_ time: CMTime) {
    trimEnd = time
    playerController.trimEnd = time
  }

  func setPipCorner(_ corner: PiPCorner) {
    let margin: CGFloat = 0.02
    let w = pipLayout.relativeWidth
    let aspect: CGFloat = {
      guard let ws = result.webcamSize else { return 0.75 }
      return ws.height / max(ws.width, 1)
    }()
    let h = w * aspect * (result.screenSize.width / max(result.screenSize.height, 1))

    switch corner {
    case .topLeft:
      pipLayout.relativeX = margin
      pipLayout.relativeY = margin
    case .topRight:
      pipLayout.relativeX = 1.0 - w - margin
      pipLayout.relativeY = margin
    case .bottomLeft:
      pipLayout.relativeX = margin
      pipLayout.relativeY = 1.0 - h - margin
    case .bottomRight:
      pipLayout.relativeX = 1.0 - w - margin
      pipLayout.relativeY = 1.0 - h - margin
    }
  }

  func canvasSize(for screenSize: CGSize) -> CGSize {
    if padding > 0 {
      let scale = 1.0 + 2.0 * padding
      return CGSize(width: screenSize.width * scale, height: screenSize.height * scale)
    }
    return screenSize
  }

  func export(settings: ExportSettings) async throws -> URL {
    isExporting = true
    exportProgress = 0
    defer { isExporting = false }

    let state = self
    let url = try await VideoCompositor.export(
      result: result,
      pipLayout: pipLayout,
      trimRange: CMTimeRange(start: trimStart, end: trimEnd),
      backgroundStyle: backgroundStyle,
      padding: padding,
      videoCornerRadius: videoCornerRadius,
      exportSettings: settings,
      progressHandler: { progress in
        state.exportProgress = progress
      }
    )
    exportProgress = 1.0
    logger.info("Export finished: \(url.path)")
    return url
  }

  func deleteRecording() {
    let fm = FileManager.default
    try? fm.removeItem(at: result.screenVideoURL)
    if let webcamURL = result.webcamVideoURL {
      try? fm.removeItem(at: webcamURL)
    }
    if let sysURL = result.systemAudioURL {
      try? fm.removeItem(at: sysURL)
    }
    if let micURL = result.microphoneAudioURL {
      try? fm.removeItem(at: micURL)
    }
  }

  func openSaveFolder() {
    let dir = FileManager.default.defaultSaveDirectory()
    NSWorkspace.shared.open(dir)
  }

  func teardown() {
    playerController.teardown()
  }
}

enum PiPCorner {
  case topLeft, topRight, bottomLeft, bottomRight
}
