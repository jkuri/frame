import CoreGraphics
import Foundation
import Logging
@preconcurrency import ScreenCaptureKit

actor RecordingCoordinator {
  private var captureSession: ScreenCaptureSession?
  private var videoWriter: VideoWriter?
  private let logger = Logger(label: "eu.jankuri.frame.recording-coordinator")

  func startRecording(target: CaptureTarget, fps: Int = 60) async throws -> Date {
    let tempURL = FileManager.default.tempRecordingURL()

    let content = try await Permissions.fetchShareableContent()
    guard let display = content.displays.first(where: { $0.displayID == target.displayID }) else {
      throw CaptureError.displayNotFound
    }

    let displayScale: CGFloat = {
      guard let mode = CGDisplayCopyDisplayMode(target.displayID) else { return 2.0 }
      let px = CGFloat(mode.pixelWidth)
      let pt = CGFloat(mode.width)
      return pt > 0 ? px / pt : 2.0
    }()

    let sourceRect: CGRect
    switch target {
    case .region(let selection):
      sourceRect = selection.screenCaptureKitRect
    case .window(let window):
      // Initialize with window frame, but content filter handles actual capture
      sourceRect = CGRect(origin: .zero, size: CGSize(width: CGFloat(window.frame.width), height: CGFloat(window.frame.height)))
    case .screen(let screen):
       sourceRect = screen.frame
    }

    let pixelW = Int(round(sourceRect.width * displayScale)) & ~1
    let pixelH = Int(round(sourceRect.height * displayScale)) & ~1

    let writer = try VideoWriter(
      outputURL: tempURL,
      width: pixelW,
      height: pixelH
    )
    let session = ScreenCaptureSession(videoWriter: writer)
    try await session.start(target: target, display: display, displayScale: displayScale, fps: fps)

    self.videoWriter = writer
    self.captureSession = session

    let startedAt = Date()
    logger.info("Recording started")
    return startedAt
  }

  func stopRecording() async throws -> URL? {
    try await captureSession?.stop()
    captureSession = nil

    guard let outputURL = await videoWriter?.finish() else {
      logger.error("Video writer produced no output")
      return nil
    }
    videoWriter = nil

    let destination = FileManager.default.defaultSaveURL(for: outputURL)
    try FileManager.default.moveToFinal(from: outputURL, to: destination)

    logger.info("Recording saved", metadata: ["path": "\(destination.path)"])
    return destination
  }
}
