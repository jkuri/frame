@preconcurrency import AVFoundation
import Foundation
import RNNoise

private struct AudioChunkParams: @unchecked Sendable {
  let input: UnsafeMutablePointer<Float>
  let output: UnsafeMutablePointer<Float>
  let processStart: Int
  let processEnd: Int
  let outputStart: Int
  let sampleCount: Int
}

enum RNNoiseProcessor {
  private static let frameSize = 480
  private static let overlapFrames = 20

  static func processFile(
    inputURL: URL,
    outputURL: URL,
    intensity: Float = 0.5,
    onProgress: (@MainActor @Sendable (Double) -> Void)? = nil
  ) async throws {
    let sourceFile = try AVAudioFile(forReading: inputURL)
    let sourceFormat = sourceFile.processingFormat
    let totalFrames = AVAudioFrameCount(sourceFile.length)

    let monoFormat = AVAudioFormat(
      commonFormat: .pcmFormatFloat32,
      sampleRate: 48000,
      channels: 1,
      interleaved: false
    )!

    let convertedBuffer = try convertToMono48k(
      sourceFile: sourceFile,
      sourceFormat: sourceFormat,
      monoFormat: monoFormat,
      totalFrames: totalFrames
    )

    let sampleCount = Int(convertedBuffer.frameLength)
    guard sampleCount > 0, let channelData = convertedBuffer.floatChannelData?[0] else {
      throw CaptureError.recordingFailed("No audio data after conversion")
    }

    let clamped = max(0, min(1, intensity))
    let passes: Int
    let wet: Float
    if clamped <= 0.5 {
      passes = 1
      wet = clamped * 2.0
    } else {
      passes = 2
      wet = 1.0
    }
    let dry = 1.0 - wet

    let inputPointer = UnsafeMutablePointer<Float>.allocate(capacity: sampleCount)
    memcpy(inputPointer, channelData, sampleCount * MemoryLayout<Float>.size)

    var currentInput = inputPointer
    var outputSamples: UnsafeMutablePointer<Float>? = nil

    do {
      for pass in 0..<passes {
        let isLastPass = pass == passes - 1
        let passProgress: (@MainActor @Sendable (Double) -> Void)?
        if passes > 1, let onProgress {
          let passIndex = pass
          let totalPasses = passes
          passProgress = { p in
            let combined = Double(passIndex) / Double(totalPasses) + p / Double(totalPasses)
            onProgress(combined)
          }
        } else {
          passProgress = onProgress
        }
        let passOutput = try await processParallel(
          input: currentInput,
          sampleCount: sampleCount,
          onProgress: passProgress
        )

        if isLastPass && dry > 0 {
          for i in 0..<sampleCount {
            passOutput[i] = dry * channelData[i] + wet * passOutput[i]
          }
        }

        if pass > 0 {
          currentInput.deallocate()
        }
        currentInput = passOutput
        outputSamples = passOutput
      }
    } catch {
      if currentInput != inputPointer { currentInput.deallocate() }
      inputPointer.deallocate()
      throw error
    }
    inputPointer.deallocate()

    guard let outputSamples else {
      throw CaptureError.recordingFailed("No output from noise reduction")
    }

    let outputBuffer = AVAudioPCMBuffer(
      pcmFormat: monoFormat,
      frameCapacity: AVAudioFrameCount(sampleCount)
    )!
    outputBuffer.frameLength = AVAudioFrameCount(sampleCount)
    memcpy(outputBuffer.floatChannelData![0], outputSamples, sampleCount * MemoryLayout<Float>.size)
    outputSamples.deallocate()

    let stereoFormat = AVAudioFormat(
      commonFormat: .pcmFormatFloat32,
      sampleRate: 48000,
      channels: 2,
      interleaved: false
    )!
    let stereoBuffer = AVAudioPCMBuffer(
      pcmFormat: stereoFormat,
      frameCapacity: AVAudioFrameCount(sampleCount)
    )!
    stereoBuffer.frameLength = AVAudioFrameCount(sampleCount)
    let monoData = outputBuffer.floatChannelData![0]
    memcpy(stereoBuffer.floatChannelData![0], monoData, sampleCount * MemoryLayout<Float>.size)
    memcpy(stereoBuffer.floatChannelData![1], monoData, sampleCount * MemoryLayout<Float>.size)

    let outputSettings: [String: Any] = [
      AVFormatIDKey: kAudioFormatMPEG4AAC,
      AVSampleRateKey: 48000.0,
      AVNumberOfChannelsKey: 2,
      AVEncoderBitRateKey: 320_000,
    ]

    let outputFile = try AVAudioFile(forWriting: outputURL, settings: outputSettings)
    try outputFile.write(from: stereoBuffer)
  }

  private static func processParallel(
    input: UnsafeMutablePointer<Float>,
    sampleCount: Int,
    onProgress: (@MainActor @Sendable (Double) -> Void)?
  ) async throws -> UnsafeMutablePointer<Float> {
    let coreCount = max(1, ProcessInfo.processInfo.activeProcessorCount)
    let chunkCount = min(coreCount, max(1, sampleCount / (frameSize * 100)))
    let baseSamplesPerChunk = sampleCount / chunkCount
    let overlapSamples = overlapFrames * frameSize

    let output = UnsafeMutablePointer<Float>.allocate(capacity: sampleCount)

    var completed = 0
    try await withThrowingTaskGroup(of: Void.self) { group in
      for chunkIdx in 0..<chunkCount {
        let outputStart = chunkIdx * baseSamplesPerChunk
        let outputEnd: Int
        if chunkIdx == chunkCount - 1 {
          outputEnd = sampleCount
        } else {
          outputEnd = (chunkIdx + 1) * baseSamplesPerChunk
        }

        let warmupStart = max(0, outputStart - overlapSamples)
        let params = AudioChunkParams(
          input: input,
          output: output,
          processStart: warmupStart,
          processEnd: outputEnd,
          outputStart: outputStart,
          sampleCount: sampleCount
        )

        group.addTask {
          try Task.checkCancellation()
          processChunk(params)
        }
      }

      for try await _ in group {
        completed += 1
        await onProgress?(Double(completed) / Double(chunkCount))
      }
    }

    return output
  }

  private static func processChunk(
    _ p: AudioChunkParams
  ) {
    guard let state = rnnoise_create(nil) else { return }
    defer { rnnoise_destroy(state) }

    var inFrame = [Float](repeating: 0, count: frameSize)
    var outFrame = [Float](repeating: 0, count: frameSize)
    let scale: Float = 32768.0
    let invScale: Float = 1.0 / 32768.0

    var offset = p.processStart
    while offset < p.processEnd {
      let remaining = p.processEnd - offset
      let count = min(remaining, frameSize)

      for i in 0..<count {
        inFrame[i] = p.input[offset + i] * scale
      }
      for i in count..<frameSize {
        inFrame[i] = 0
      }

      _ = rnnoise_process_frame(state, &outFrame, inFrame)

      if offset >= p.outputStart {
        for i in 0..<count {
          p.output[offset + i] = outFrame[i] * invScale
        }
      }

      offset += count
    }
  }

  private static func convertToMono48k(
    sourceFile: AVAudioFile,
    sourceFormat: AVAudioFormat,
    monoFormat: AVAudioFormat,
    totalFrames: AVAudioFrameCount
  ) throws -> AVAudioPCMBuffer {
    let converter = AVAudioConverter(from: sourceFormat, to: monoFormat)!
    let readBuffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: 4096)!
    let capacity =
      AVAudioFrameCount(
        Double(totalFrames) * 48000.0 / sourceFormat.sampleRate
      ) + 4096
    let convertBuffer = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: capacity)!

    nonisolated(unsafe) let unsafeReadBuffer = readBuffer
    nonisolated(unsafe) var inputDone = false

    let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
      if inputDone {
        outStatus.pointee = .endOfStream
        return nil
      }
      do {
        unsafeReadBuffer.frameLength = 0
        try sourceFile.read(into: unsafeReadBuffer)
        if unsafeReadBuffer.frameLength == 0 {
          inputDone = true
          outStatus.pointee = .endOfStream
          return nil
        }
        outStatus.pointee = .haveData
        return unsafeReadBuffer
      } catch {
        inputDone = true
        outStatus.pointee = .endOfStream
        return nil
      }
    }

    let status = converter.convert(to: convertBuffer, error: nil, withInputFrom: inputBlock)
    guard status != .error else {
      throw CaptureError.recordingFailed("Failed to convert audio to 48kHz mono")
    }
    return convertBuffer
  }

}
