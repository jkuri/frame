import AVFoundation
import Logging

enum VideoTranscoder {
  private static let logger = Logger(label: "eu.jankuri.frame.video-transcoder")

  static func transcode(input inputURL: URL, to outputURL: URL) async throws -> URL {
    if FileManager.default.fileExists(atPath: outputURL.path) {
      try FileManager.default.removeItem(at: outputURL)
    }

    let asset = AVURLAsset(url: inputURL)
    let videoTrack = try await asset.loadTracks(withMediaType: .video).first!
    let naturalSize = try await videoTrack.load(.naturalSize)
    let width = Int(naturalSize.width)
    let height = Int(naturalSize.height)

    let reader = try AVAssetReader(asset: asset)
    let readerOutput = AVAssetReaderTrackOutput(
      track: videoTrack,
      outputSettings: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
      ]
    )
    readerOutput.alwaysCopiesSampleData = false
    reader.add(readerOutput)

    let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
    let videoSettings: [String: Any] = [
      AVVideoCodecKey: AVVideoCodecType.hevc,
      AVVideoWidthKey: width,
      AVVideoHeightKey: height,
      AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: width * height * 12,
        AVVideoExpectedSourceFrameRateKey: 60,
        AVVideoMaxKeyFrameIntervalKey: 120,
      ] as [String: Any],
    ]
    let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
    writerInput.expectsMediaDataInRealTime = false
    writer.add(writerInput)

    reader.startReading()
    writer.startWriting()
    writer.startSession(atSourceTime: .zero)

    logger.info("Transcoding started: \(inputURL.lastPathComponent)")

    nonisolated(unsafe) let input = writerInput
    nonisolated(unsafe) let output = readerOutput
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      let queue = DispatchQueue(label: "eu.jankuri.frame.video-transcoder.queue")
      input.requestMediaDataWhenReady(on: queue) {
        while input.isReadyForMoreMediaData {
          guard let sampleBuffer = output.copyNextSampleBuffer() else {
            input.markAsFinished()
            continuation.resume()
            return
          }
          input.append(sampleBuffer)
        }
      }
    }

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      writer.finishWriting {
        continuation.resume()
      }
    }

    guard writer.status == .completed else {
      throw CaptureError.recordingFailed(writer.error?.localizedDescription ?? "Transcode failed")
    }

    try FileManager.default.removeItem(at: inputURL)
    logger.info("Transcoding finished: \(outputURL.lastPathComponent)")

    return outputURL
  }
}
