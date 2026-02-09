import AVFoundation
import CoreMedia
import CoreVideo
import Logging

final class VideoWriter: @unchecked Sendable {
  private var assetWriter: AVAssetWriter?
  private var videoInput: AVAssetWriterInput?
  private var adaptor: AVAssetWriterInputPixelBufferAdaptor?
  private var isStarted = false
  private let outputURL: URL
  private let logger = Logger(label: "eu.jankuri.frame.video-writer")
  let queue = DispatchQueue(label: "eu.jankuri.frame.video-writer.queue", qos: .userInteractive)
  var writtenFrames = 0
  var droppedFrames = 0

  func resetStats() {
    writtenFrames = 0
    droppedFrames = 0
  }

  init(outputURL: URL, width: Int, height: Int) throws {
    self.outputURL = outputURL

    if FileManager.default.fileExists(atPath: outputURL.path) {
      try FileManager.default.removeItem(at: outputURL)
    }

    let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

    let videoSettings: [String: Any] = [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: width,
      AVVideoHeightKey: height,
      AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: width * height * 10,
        AVVideoExpectedSourceFrameRateKey: 60,
        AVVideoMaxKeyFrameIntervalKey: 120,
        AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel,
        AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCAVLC,
        AVVideoAllowFrameReorderingKey: false,
      ] as [String: Any],
    ]

    let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
    input.expectsMediaDataInRealTime = true

    let adaptor = AVAssetWriterInputPixelBufferAdaptor(
      assetWriterInput: input,
      sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        kCVPixelBufferWidthKey as String: width,
        kCVPixelBufferHeightKey as String: height,
      ]
    )

    writer.add(input)

    self.assetWriter = writer
    self.videoInput = input
    self.adaptor = adaptor
  }

  func appendPixelBuffer(_ pixelBuffer: CVPixelBuffer, at timestamp: CMTime) {
    dispatchPrecondition(condition: .onQueue(queue))

    guard let assetWriter, let videoInput, let adaptor else { return }

    if !isStarted {
      guard assetWriter.startWriting() else {
        logger.error("Failed to start writing: \(assetWriter.error?.localizedDescription ?? "unknown")")
        return
      }
      assetWriter.startSession(atSourceTime: timestamp)
      isStarted = true
      logger.info("Video writing started")
    }

    guard videoInput.isReadyForMoreMediaData else {
      droppedFrames += 1
      return
    }

    adaptor.append(pixelBuffer, withPresentationTime: timestamp)
    writtenFrames += 1
  }

  func finish() async -> URL? {
    return await withCheckedContinuation { continuation in
      queue.async { [self] in
        guard let assetWriter, let videoInput else {
          continuation.resume(returning: nil)
          return
        }

        guard isStarted else {
          logger.warning("Writer was never started, nothing to finish")
          continuation.resume(returning: nil)
          return
        }

        videoInput.markAsFinished()

        nonisolated(unsafe) let writer = assetWriter
        writer.finishWriting {
          if writer.status == .completed {
            self.logger.info("Video writing finished: \(self.outputURL.lastPathComponent)")
            continuation.resume(returning: self.outputURL)
          } else {
            self.logger.error("Video writing failed: \(writer.error?.localizedDescription ?? "unknown")")
            continuation.resume(returning: nil)
          }
        }
      }
    }
  }
}
