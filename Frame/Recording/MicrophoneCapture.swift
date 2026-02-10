import AVFoundation
import Foundation
import Logging

struct MicrophoneFormat: Sendable {
  let sampleRate: Double
  let channelCount: Int
}

final class MicrophoneCapture: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate, @unchecked Sendable {
  private var captureSession: AVCaptureSession?
  private let videoWriter: VideoWriter
  private let logger = Logger(label: "eu.jankuri.frame.microphone-capture")
  private let micQueue = DispatchQueue(label: "eu.jankuri.frame.microphone-capture.queue", qos: .userInteractive)

  init(videoWriter: VideoWriter) {
    self.videoWriter = videoWriter
    super.init()
  }

  static func deviceFormat(deviceId: String) -> MicrophoneFormat? {
    let discovery = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.microphone],
      mediaType: .audio,
      position: .unspecified
    )
    guard let device = discovery.devices.first(where: { $0.uniqueID == deviceId }) else {
      return nil
    }
    let desc = device.activeFormat.formatDescription
    let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(desc)?.pointee
    let sampleRate = asbd?.mSampleRate ?? 48000
    let channels = Int(asbd?.mChannelsPerFrame ?? 1)
    return MicrophoneFormat(sampleRate: sampleRate, channelCount: channels)
  }

  func start(deviceId: String) async throws {
    let granted = await AVCaptureDevice.requestAccess(for: .audio)
    guard granted else {
      logger.error("Microphone permission denied")
      throw CaptureError.permissionDenied
    }

    let discovery = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.microphone],
      mediaType: .audio,
      position: .unspecified
    )
    guard let device = discovery.devices.first(where: { $0.uniqueID == deviceId }) else {
      logger.error("Microphone device not found: \(deviceId)")
      throw CaptureError.microphoneNotFound
    }

    let session = AVCaptureSession()
    let input = try AVCaptureDeviceInput(device: device)
    guard session.canAddInput(input) else {
      throw CaptureError.microphoneNotFound
    }
    session.addInput(input)

    let output = AVCaptureAudioDataOutput()
    output.setSampleBufferDelegate(self, queue: micQueue)
    guard session.canAddOutput(output) else {
      throw CaptureError.microphoneNotFound
    }
    session.addOutput(output)

    let desc = device.activeFormat.formatDescription
    let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(desc)?.pointee
    logger.info("Microphone format: sampleRate=\(asbd?.mSampleRate ?? 0) channels=\(asbd?.mChannelsPerFrame ?? 0)")

    session.startRunning()
    self.captureSession = session
    logger.info("Microphone capture started: \(device.localizedName)")
  }

  func stop() {
    captureSession?.stopRunning()
    captureSession = nil
    logger.info("Microphone capture stopped")
  }

  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    videoWriter.appendMicrophoneAudioSample(sampleBuffer)
  }
}
