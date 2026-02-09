import AppKit
import Foundation
import Logging
import SwiftUI

@MainActor
@Observable
final class SessionState {
  var state: CaptureState = .idle
  var lastRecordingURL: URL?

  private let logger = Logger(label: "eu.jankuri.frame.session")
  private var selectionCoordinator: SelectionCoordinator?
  private var recordingCoordinator: RecordingCoordinator?
  private var storedSelection: SelectionRect?

  weak var overlayView: SelectionOverlayView?

  func beginSelection() throws {
    guard case .idle = state else {
      throw CaptureError.invalidTransition(from: "\(state)", to: "selecting")
    }

    guard Permissions.hasScreenRecordingPermission else {
      Permissions.requestScreenRecordingPermission()
      throw CaptureError.permissionDenied
    }

    state = .selecting
    storedSelection = nil

    let coordinator = SelectionCoordinator()
    selectionCoordinator = coordinator
    coordinator.beginSelection(session: self)
  }

  func confirmSelection(_ selection: SelectionRect) {
    selectionCoordinator?.destroyOverlay()
    selectionCoordinator?.showRecordingBorder(screenRect: selection.rect)
    storedSelection = selection
    logger.info("Selection confirmed: \(selection.rect)")

    Task {
      do {
        try await startRecording()
      } catch {
        logger.error("Failed to start recording: \(error)")
      }
    }
  }

  func cancelSelection() {
    selectionCoordinator?.destroyAll()
    selectionCoordinator = nil
    overlayView = nil
    state = .idle
    logger.info("Selection cancelled")
  }

  func updateOverlaySelection(_ rect: CGRect) {
    overlayView?.applyExternalRect(rect)
  }

  func startRecording() async throws {
    switch state {
    case .selecting, .idle:
      break
    default:
      throw CaptureError.invalidTransition(from: "\(state)", to: "recording")
    }
    guard let selection = storedSelection else {
      throw CaptureError.noSelectionStored
    }

    let coordinator = RecordingCoordinator()
    self.recordingCoordinator = coordinator
    overlayView = nil

    let startedAt = try await coordinator.startRecording(selection: selection)
    state = .recording(startedAt: startedAt)
  }

  func stopRecording() async throws {
    switch state {
    case .recording, .paused:
      break
    default:
      throw CaptureError.invalidTransition(from: "\(state)", to: "processing")
    }

    state = .processing
    selectionCoordinator?.destroyAll()
    selectionCoordinator = nil

    if let url = try await recordingCoordinator?.stopRecording() {
      lastRecordingURL = url
      logger.info("Recording saved to \(url.path)")
    }

    recordingCoordinator = nil
    storedSelection = nil
    state = .idle
  }

  func pauseRecording() {
    guard case .recording(let startedAt) = state else { return }
    let elapsed = Date().timeIntervalSince(startedAt)
    state = .paused(elapsed: elapsed)
  }

  func resumeRecording() {
    guard case .paused(let elapsed) = state else { return }
    let resumedAt = Date().addingTimeInterval(-elapsed)
    state = .recording(startedAt: resumedAt)
  }
}
