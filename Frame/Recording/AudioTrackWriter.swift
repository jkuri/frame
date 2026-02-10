import AVFoundation
import CoreMedia
import Logging

final class AudioTrackWriter: @unchecked Sendable {
  private var assetWriter: AVAssetWriter?
  private var audioInput: AVAssetWriterInput?
  private var isStarted = false
  private let outputURL: URL
  private let outputSettings: [String: Any]
  private let logger: Logger
  let queue: DispatchQueue
  private var isPaused = false
  private var timeOffset = CMTime.zero

  init(outputURL: URL, label: String, sampleRate: Double, channelCount: Int) throws {
    self.outputURL = outputURL
    self.logger = Logger(label: "eu.jankuri.frame.audio-track-writer.\(label)")
    self.queue = DispatchQueue(label: "eu.jankuri.frame.audio-track-writer.\(label).queue", qos: .userInteractive)
    self.outputSettings = [
      AVFormatIDKey: kAudioFormatMPEG4AAC,
      AVSampleRateKey: sampleRate,
      AVNumberOfChannelsKey: channelCount,
      AVEncoderBitRateKey: 128_000,
    ]

    if FileManager.default.fileExists(atPath: outputURL.path) {
      try FileManager.default.removeItem(at: outputURL)
    }

    self.assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .m4a)
  }

  func pause() {
    queue.async {
      self.isPaused = true
    }
  }

  func resume(withOffset offset: CMTime) {
    queue.async {
      self.isPaused = false
      self.timeOffset = offset
    }
  }

  func appendSample(_ sampleBuffer: CMSampleBuffer) {
    dispatchPrecondition(condition: .onQueue(queue))

    guard let assetWriter else { return }

    if isPaused { return }

    let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
    let adjustedPTS = CMTimeSubtract(pts, timeOffset)

    if !isStarted {
      let formatHint = CMSampleBufferGetFormatDescription(sampleBuffer)
      let input = AVAssetWriterInput(mediaType: .audio, outputSettings: outputSettings, sourceFormatHint: formatHint)
      input.expectsMediaDataInRealTime = true
      assetWriter.add(input)
      self.audioInput = input

      guard assetWriter.startWriting() else {
        logger.error("Failed to start audio writing: \(assetWriter.error?.localizedDescription ?? "unknown")")
        self.assetWriter = nil
        self.audioInput = nil
        return
      }
      assetWriter.startSession(atSourceTime: adjustedPTS)
      isStarted = true
      logger.info("Audio writing started")
    }

    guard let audioInput, audioInput.isReadyForMoreMediaData else { return }

    if CMTimeCompare(timeOffset, .zero) > 0 {
      var timingInfo = CMSampleTimingInfo(
        duration: CMSampleBufferGetDuration(sampleBuffer),
        presentationTimeStamp: adjustedPTS,
        decodeTimeStamp: .invalid
      )
      var adjustedBuffer: CMSampleBuffer?
      let status = CMSampleBufferCreateCopyWithNewTiming(
        allocator: kCFAllocatorDefault,
        sampleBuffer: sampleBuffer,
        sampleTimingEntryCount: 1,
        sampleTimingArray: &timingInfo,
        sampleBufferOut: &adjustedBuffer
      )
      if status == noErr, let adjusted = adjustedBuffer {
        audioInput.append(adjusted)
        return
      }
    }

    audioInput.append(sampleBuffer)
  }

  func finish() async -> URL? {
    return await withCheckedContinuation { continuation in
      queue.async { [self] in
        guard let assetWriter, let audioInput else {
          continuation.resume(returning: nil)
          return
        }

        guard isStarted else {
          logger.warning("Audio writer was never started, nothing to finish")
          continuation.resume(returning: nil)
          return
        }

        audioInput.markAsFinished()

        nonisolated(unsafe) let writer = assetWriter
        writer.finishWriting {
          if writer.status == .completed {
            self.logger.info("Audio writing finished: \(self.outputURL.lastPathComponent)")
            continuation.resume(returning: self.outputURL)
          } else {
            self.logger.error("Audio writing failed: \(writer.error?.localizedDescription ?? "unknown")")
            continuation.resume(returning: nil)
          }
        }
      }
    }
  }
}
