import AVFoundation
import CoreMedia
import Foundation
import Logging
import VideoToolbox

extension VideoCompositor {
  private final class OrderedFrameWriter: @unchecked Sendable {
    private let lock = NSLock()
    private var pending: [Int: (CVPixelBuffer, CMTime)] = [:]
    private var nextIndex = 0
    private var draining = false
    private let adaptor: AVAssetWriterInputPixelBufferAdaptor
    private let input: AVAssetWriterInput
    private var finished = false
    private var hasSignaled = false
    private let doneSignal = DispatchSemaphore(value: 0)

    private let totalFrames: Int
    private let progressHandler: (@MainActor @Sendable (Double, Double?) -> Void)?
    private let startTime: CFAbsoluteTime
    private let backpressure: DispatchSemaphore?

    init(
      adaptor: AVAssetWriterInputPixelBufferAdaptor,
      input: AVAssetWriterInput,
      totalFrames: Int,
      progressHandler: (@MainActor @Sendable (Double, Double?) -> Void)?,
      backpressure: DispatchSemaphore? = nil
    ) {
      self.adaptor = adaptor
      self.input = input
      self.totalFrames = totalFrames
      self.progressHandler = progressHandler
      self.startTime = CFAbsoluteTimeGetCurrent()
      self.backpressure = backpressure
    }

    func start() {
      input.requestMediaDataWhenReady(
        on: DispatchQueue(label: "eu.jankuri.reframed.video-writer", qos: .userInteractive)
      ) { [weak self] in
        self?.drain()
      }
    }

    func submit(index: Int, buffer: CVPixelBuffer, time: CMTime) {
      lock.lock()
      pending[index] = (buffer, time)
      lock.unlock()
      drain()
    }

    func finish() {
      lock.lock()
      finished = true
      lock.unlock()
      drain()
    }

    func waitUntilDone() {
      doneSignal.wait()
    }

    private func drain() {
      lock.lock()
      if draining {
        lock.unlock()
        return
      }
      draining = true

      while true {
        guard input.isReadyForMoreMediaData, let (buf, time) = pending[nextIndex] else {
          break
        }
        pending.removeValue(forKey: nextIndex)
        nextIndex += 1
        let writtenCount = nextIndex
        lock.unlock()

        adaptor.append(buf, withPresentationTime: time)
        backpressure?.signal()

        if writtenCount % 30 == 0 || writtenCount == totalFrames {
          let progress = (Double(writtenCount) / Double(max(totalFrames, 1))) * 0.99
          let elapsed = CFAbsoluteTimeGetCurrent() - startTime
          let remaining = Double(totalFrames - writtenCount)
          let secsPerFrame = elapsed / Double(writtenCount)
          let eta = remaining * secsPerFrame
          if let handler = progressHandler {
            Task { @MainActor in handler(progress, eta) }
          }
        }

        lock.lock()
      }

      let shouldSignalDone = finished && pending.isEmpty && !hasSignaled
      if shouldSignalDone { hasSignaled = true }
      draining = false
      lock.unlock()

      if shouldSignalDone {
        doneSignal.signal()
      }
    }
  }

  static func parallelRenderExport(
    composition: AVComposition,
    instruction: CompositionInstruction,
    renderSize: CGSize,
    fps: Int,
    trimDuration: CMTime,
    outputURL: URL,
    fileType: AVFileType,
    codec: ExportCodec,
    audioMix: AVAudioMix? = nil,
    audioBitrate: Int = 320_000,
    progressHandler: (@MainActor @Sendable (Double, Double?) -> Void)?
  ) async throws {
    let reader = try AVAssetReader(asset: composition)
    reader.timeRange = CMTimeRange(start: .zero, duration: trimDuration)

    guard
      let screenTrack = composition.tracks(withMediaType: .video)
        .first(where: { $0.trackID == instruction.screenTrackID })
    else {
      throw CaptureError.recordingFailed("No screen track found")
    }

    let screenOutput = AVAssetReaderTrackOutput(
      track: screenTrack,
      outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_64RGBAHalf]
    )
    screenOutput.alwaysCopiesSampleData = false
    reader.add(screenOutput)

    var webcamOutput: AVAssetReaderTrackOutput?
    if let webcamTrackID = instruction.webcamTrackID,
      let webcamTrack = composition.tracks(withMediaType: .video)
        .first(where: { $0.trackID == webcamTrackID })
    {
      let output = AVAssetReaderTrackOutput(
        track: webcamTrack,
        outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_64RGBAHalf]
      )
      output.alwaysCopiesSampleData = false
      reader.add(output)
      webcamOutput = output
    }

    let audioTracks = composition.tracks(withMediaType: .audio)

    var audioReader: AVAssetReader?
    var audioOutput: AVAssetReaderAudioMixOutput?
    if !audioTracks.isEmpty {
      let aReader = try AVAssetReader(asset: composition)
      aReader.timeRange = CMTimeRange(start: .zero, duration: trimDuration)
      let mixOutput = AVAssetReaderAudioMixOutput(audioTracks: audioTracks, audioSettings: nil)
      if let audioMix {
        mixOutput.audioMix = audioMix
      }
      mixOutput.alwaysCopiesSampleData = false
      aReader.add(mixOutput)
      audioOutput = mixOutput
      audioReader = aReader
    }

    let assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: fileType)

    let videoCodec: AVVideoCodecType = codec.videoCodecType
    let parallelColorProperties: [String: Any] = [
      AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
      AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
      AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2,
    ]
    let videoOutputSettings: [String: Any]
    if codec.isProRes {
      videoOutputSettings = [
        AVVideoCodecKey: videoCodec,
        AVVideoWidthKey: Int(renderSize.width),
        AVVideoHeightKey: Int(renderSize.height),
        AVVideoColorPropertiesKey: parallelColorProperties,
      ]
    } else {
      let pixels = Double(renderSize.width * renderSize.height)
      var compressionProperties: [String: Any] = [
        AVVideoExpectedSourceFrameRateKey: fps,
        AVVideoMaxKeyFrameIntervalKey: fps,
      ]
      if codec == .h265 {
        compressionProperties[AVVideoAverageBitRateKey] = pixels * 5
        compressionProperties[AVVideoProfileLevelKey] = kVTProfileLevel_HEVC_Main10_AutoLevel
      } else {
        compressionProperties[AVVideoAverageBitRateKey] = pixels * 7
        compressionProperties[AVVideoProfileLevelKey] = AVVideoProfileLevelH264HighAutoLevel
      }
      videoOutputSettings = [
        AVVideoCodecKey: videoCodec,
        AVVideoWidthKey: Int(renderSize.width),
        AVVideoHeightKey: Int(renderSize.height),
        AVVideoColorPropertiesKey: parallelColorProperties,
        AVVideoCompressionPropertiesKey: compressionProperties,
      ]
    }
    let videoInput = AVAssetWriterInput(
      mediaType: .video,
      outputSettings: videoOutputSettings
    )
    videoInput.expectsMediaDataInRealTime = false

    let adaptor = AVAssetWriterInputPixelBufferAdaptor(
      assetWriterInput: videoInput,
      sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_64RGBAHalf,
        kCVPixelBufferWidthKey as String: Int(renderSize.width),
        kCVPixelBufferHeightKey as String: Int(renderSize.height),
      ]
    )
    assetWriter.add(videoInput)

    var audioWriterInput: AVAssetWriterInput?
    if !audioTracks.isEmpty {
      let aInput = AVAssetWriterInput(
        mediaType: .audio,
        outputSettings: [
          AVFormatIDKey: kAudioFormatMPEG4AAC,
          AVNumberOfChannelsKey: 2,
          AVSampleRateKey: 44100,
          AVEncoderBitRateKey: audioBitrate,
        ]
      )
      aInput.expectsMediaDataInRealTime = false
      assetWriter.add(aInput)
      audioWriterInput = aInput
    }

    reader.startReading()
    audioReader?.startReading()
    assetWriter.startWriting()
    assetWriter.startSession(atSourceTime: .zero)

    let coreCount = ProcessInfo.processInfo.activeProcessorCount
    let batchSize = max(coreCount * 3, 24)

    let bytesPerFrame = Int(renderSize.width) * Int(renderSize.height) * 8
    let maxMemoryBytes = 1_500_000_000
    let maxInFlight = max(batchSize * 3, min(maxMemoryBytes / max(bytesPerFrame, 1), 120))

    var poolRef: CVPixelBufferPool?
    let poolAttrs: NSDictionary = [kCVPixelBufferPoolMinimumBufferCountKey: maxInFlight + 4]
    let pbAttrs: NSDictionary = [
      kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_64RGBAHalf,
      kCVPixelBufferWidthKey: Int(renderSize.width),
      kCVPixelBufferHeightKey: Int(renderSize.height),
    ]
    CVPixelBufferPoolCreate(nil, poolAttrs, pbAttrs, &poolRef)
    guard let outputPool = poolRef else {
      throw CaptureError.recordingFailed("Failed to create pixel buffer pool")
    }

    let totalFrames = Int(ceil(CMTimeGetSeconds(trimDuration) * Double(fps)))
    let timescale = CMTimeScale(fps)

    nonisolated(unsafe) let pipelineReader = reader
    nonisolated(unsafe) let pipelineScreenOutput = screenOutput
    nonisolated(unsafe) let pipelineWebcamOutput = webcamOutput
    nonisolated(unsafe) let pipelineAudioReader = audioReader
    nonisolated(unsafe) let pipelineAudioOutput = audioOutput
    nonisolated(unsafe) let pipelineAudioWriterInput = audioWriterInput
    nonisolated(unsafe) let pipelineOutputPool = outputPool
    nonisolated(unsafe) let pipelineWriter = assetWriter
    nonisolated(unsafe) let pipelineVideoInput = videoInput
    nonisolated(unsafe) let pipelineAdaptor = adaptor

    nonisolated(unsafe) let cancelled = UnsafeMutablePointer<Bool>.allocate(capacity: 1)
    cancelled.initialize(to: false)
    defer { cancelled.deallocate() }

    try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, any Error>) in
        DispatchQueue.global(qos: .userInitiated).async {
          let audioGroup = DispatchGroup()
          if let aOut = pipelineAudioOutput, let aIn = pipelineAudioWriterInput,
            pipelineAudioReader?.status == .reading
          {
            nonisolated(unsafe) let safeAudioOutput = aOut
            nonisolated(unsafe) let safeAudioInput = aIn
            audioGroup.enter()
            let audioQueue = DispatchQueue(label: "eu.jankuri.reframed.audio", qos: .userInitiated)
            safeAudioInput.requestMediaDataWhenReady(on: audioQueue) {
              while safeAudioInput.isReadyForMoreMediaData {
                if cancelled.pointee {
                  safeAudioInput.markAsFinished()
                  audioGroup.leave()
                  return
                }
                if let sample = safeAudioOutput.copyNextSampleBuffer() {
                  safeAudioInput.append(sample)
                } else {
                  safeAudioInput.markAsFinished()
                  audioGroup.leave()
                  break
                }
              }
            }
          } else {
            pipelineAudioWriterInput?.markAsFinished()
          }

          let sem = DispatchSemaphore(value: maxInFlight)
          let frameWriter = OrderedFrameWriter(
            adaptor: pipelineAdaptor,
            input: pipelineVideoInput,
            totalFrames: totalFrames,
            progressHandler: progressHandler,
            backpressure: sem
          )
          frameWriter.start()

          var latestScreenSample: CMSampleBuffer?
          var nextScreenSample: CMSampleBuffer? = pipelineScreenOutput.copyNextSampleBuffer()
          var latestWebcamSample: CMSampleBuffer?
          var nextWebcamSample: CMSampleBuffer? = pipelineWebcamOutput?.copyNextSampleBuffer()

          for batchStart in stride(from: 0, to: totalFrames, by: batchSize) {
            if cancelled.pointee { break }

            let batchEnd = min(batchStart + batchSize, totalFrames)
            let batchCount = batchEnd - batchStart

            var batchScreenSamples: [CMSampleBuffer?] = Array(repeating: nil, count: batchCount)
            var batchWebcamSamples: [CMSampleBuffer?] = Array(repeating: nil, count: batchCount)
            var batchScreenBuffers: [CVPixelBuffer?] = Array(repeating: nil, count: batchCount)
            var batchWebcamBuffers: [CVPixelBuffer?] = Array(repeating: nil, count: batchCount)
            var batchTimes: [CMTime] = Array(repeating: .zero, count: batchCount)

            for i in 0..<batchCount {
              let frameIndex = batchStart + i
              let outputTime = CMTime(value: CMTimeValue(frameIndex), timescale: timescale)
              let outputSeconds = CMTimeGetSeconds(outputTime)

              while let next = nextScreenSample {
                if CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(next))
                  <= outputSeconds + 0.001
                {
                  latestScreenSample = next
                  nextScreenSample = pipelineScreenOutput.copyNextSampleBuffer()
                } else {
                  break
                }
              }

              if pipelineWebcamOutput != nil {
                while let next = nextWebcamSample {
                  if CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(next))
                    <= outputSeconds + 0.001
                  {
                    latestWebcamSample = next
                    nextWebcamSample = pipelineWebcamOutput!.copyNextSampleBuffer()
                  } else {
                    break
                  }
                }
              }

              batchScreenSamples[i] = latestScreenSample
              batchWebcamSamples[i] = latestWebcamSample
              batchScreenBuffers[i] = latestScreenSample.flatMap { CMSampleBufferGetImageBuffer($0) }
              batchWebcamBuffers[i] = latestWebcamSample.flatMap { CMSampleBufferGetImageBuffer($0) }
              batchTimes[i] = outputTime
            }

            var outputBuffers: [CVPixelBuffer?] = Array(repeating: nil, count: batchCount)
            for i in 0..<batchCount {
              if cancelled.pointee { break }
              guard batchScreenBuffers[i] != nil else { continue }
              sem.wait()
              if cancelled.pointee { sem.signal(); break }
              var outBuf: CVPixelBuffer?
              CVPixelBufferPoolCreatePixelBuffer(nil, pipelineOutputPool, &outBuf)
              if outBuf == nil { sem.signal() }
              outputBuffers[i] = outBuf
            }

            if cancelled.pointee { break }

            nonisolated(unsafe) let screenBufs = batchScreenBuffers
            nonisolated(unsafe) let webcamBufs = batchWebcamBuffers
            nonisolated(unsafe) let outBufs = outputBuffers
            let times = batchTimes

            DispatchQueue.concurrentPerform(iterations: batchCount) { i in
              guard let screenBuf = screenBufs[i],
                let outputBuf = outBufs[i]
              else { return }
              CameraVideoCompositor.renderFrame(
                screenBuffer: screenBuf,
                webcamBuffer: webcamBufs[i],
                outputBuffer: outputBuf,
                compositionTime: times[i],
                instruction: instruction
              )
            }

            for i in 0..<batchCount {
              guard let outputBuf = outputBuffers[i] else { continue }
              frameWriter.submit(
                index: batchStart + i,
                buffer: outputBuf,
                time: batchTimes[i]
              )
            }

            batchScreenSamples.removeAll()
            batchWebcamSamples.removeAll()
          }

          frameWriter.finish()
          frameWriter.waitUntilDone()
          pipelineVideoInput.markAsFinished()
          pipelineReader.cancelReading()

          audioGroup.wait()

          if cancelled.pointee {
            pipelineWriter.cancelWriting()
            try? FileManager.default.removeItem(at: outputURL)
            cont.resume(throwing: CancellationError())
            return
          }

          pipelineWriter.finishWriting {
            if pipelineWriter.status == .failed {
              cont.resume(
                throwing: pipelineWriter.error
                  ?? CaptureError.recordingFailed("Export writing failed")
              )
            } else {
              logger.info("Parallel render export completed (\(coreCount) cores)")
              if let handler = progressHandler {
                Task { @MainActor in handler(1.0, nil) }
              }
              cont.resume()
            }
          }
        }
      }
    } onCancel: {
      cancelled.pointee = true
    }
  }
}
