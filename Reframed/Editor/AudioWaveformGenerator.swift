import AVFoundation
import Accelerate
import Foundation

struct NoiseReductionParams: Sendable {
  let highPassFreq: Float
  let lowPassFreq: Float
  let sampleRate: Double
}

@MainActor
@Observable
final class AudioWaveformGenerator {
  private(set) var samples: [Float] = []
  private(set) var isGenerating = false
  private(set) var progress: Double = 0

  func generate(from url: URL, count: Int = 200, noiseReduction: NoiseReductionParams? = nil) async {
    isGenerating = true
    progress = 0
    defer { isGenerating = false }

    let gen = self
    let handler: @MainActor @Sendable (Double) -> Void = { p in
      gen.progress = p
    }

    let result = await Task.detached(priority: .userInitiated) {
      await Self.extractSamples(from: url, count: count, noiseReduction: noiseReduction, onProgress: handler)
    }.value

    samples = result
    progress = 1.0
  }

  nonisolated private static func extractSamples(
    from url: URL,
    count: Int,
    noiseReduction: NoiseReductionParams? = nil,
    onProgress: (@MainActor @Sendable (Double) -> Void)? = nil
  ) async -> [Float] {
    let asset = AVURLAsset(url: url)
    guard let reader = try? AVAssetReader(asset: asset) else { return [] }

    let audioTracks = (try? await asset.loadTracks(withMediaType: .audio)) ?? []
    guard let track = audioTracks.first else {
      let videoTracks = (try? await asset.loadTracks(withMediaType: .video)) ?? []
      guard videoTracks.first != nil else { return [] }
      return []
    }

    let trackTimeRange = try? await track.load(.timeRange)
    let assetDuration = try? await asset.load(.duration)
    let totalDuration = CMTimeGetSeconds(trackTimeRange?.duration ?? assetDuration ?? .zero)

    let settings: [String: Any] = [
      AVFormatIDKey: kAudioFormatLinearPCM,
      AVLinearPCMBitDepthKey: 16,
      AVLinearPCMIsFloatKey: false,
      AVLinearPCMIsBigEndianKey: false,
      AVLinearPCMIsNonInterleaved: false,
    ]

    let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
    reader.add(output)
    guard reader.startReading() else { return [] }

    var allSamples: [Int16] = []
    var lastReportedTime = ProcessInfo.processInfo.systemUptime
    let updateInterval = 1.0 / 60.0

    while let buffer = output.copyNextSampleBuffer() {
      if let onProgress, totalDuration > 0 {
        let pts = CMSampleBufferGetPresentationTimeStamp(buffer)
        let currentTime = CMTimeGetSeconds(pts)

        let now = ProcessInfo.processInfo.systemUptime
        if now - lastReportedTime >= updateInterval {
          lastReportedTime = now
          let readProgress = min(max(currentTime / totalDuration, 0.0), 1.0)
          let scaledProgress = readProgress * 0.95
          await onProgress(scaledProgress)
        }
      }

      guard let blockBuffer = CMSampleBufferGetDataBuffer(buffer) else { continue }
      let length = CMBlockBufferGetDataLength(blockBuffer)
      var data = Data(count: length)
      data.withUnsafeMutableBytes { ptr in
        guard let base = ptr.baseAddress else { return }
        CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: base)
      }
      let sampleCount = length / MemoryLayout<Int16>.size
      data.withUnsafeBytes { ptr in
        guard let bound = ptr.bindMemory(to: Int16.self).baseAddress else { return }
        allSamples.append(contentsOf: UnsafeBufferPointer(start: bound, count: sampleCount))
      }
    }

    guard !allSamples.isEmpty else { return [] }

    if let nr = noiseReduction {
      let n = allSamples.count
      var floats = [Float](repeating: 0, count: n)
      vDSP_vflt16(allSamples, 1, &floats, 1, vDSP_Length(n))

      let dt = Float(1.0 / nr.sampleRate)

      let hpRC = 1.0 / (2.0 * Float.pi * nr.highPassFreq)
      let hpAlpha = hpRC / (hpRC + dt)
      var prevX = floats[0]
      var prevY = floats[0]
      for i in 1..<n {
        let x = floats[i]
        prevY = hpAlpha * (prevY + x - prevX)
        prevX = x
        floats[i] = prevY
      }

      let lpRC = 1.0 / (2.0 * Float.pi * nr.lowPassFreq)
      let lpAlpha = dt / (lpRC + dt)
      var lpPrev = floats[0]
      for i in 1..<n {
        lpPrev = lpAlpha * floats[i] + (1.0 - lpAlpha) * lpPrev
        floats[i] = lpPrev
      }

      var filtered = [Int16](repeating: 0, count: n)
      for i in 0..<n {
        filtered[i] = Int16(clamping: Int32(floats[i]))
      }
      return downsample(filtered, to: count)
    }

    return downsample(allSamples, to: count)
  }

  nonisolated private static func downsample(_ raw: [Int16], to count: Int) -> [Float] {
    let total = raw.count
    guard total > 0 && count > 0 else { return [] }

    var floatSamples = [Float](repeating: 0.0, count: total)
    vDSP_vflt16(raw, 1, &floatSamples, 1, vDSP_Length(total))

    let bucketSize = max(1, total / count)
    var result: [Float] = []
    result.reserveCapacity(count)

    floatSamples.withUnsafeBufferPointer { floatPtr in
      guard let baseAddress = floatPtr.baseAddress else { return }

      for i in 0..<count {
        let start = i * total / count
        let end = min(start + bucketSize, total)
        let currentBucketSize = end - start

        guard currentBucketSize > 0 else {
          result.append(0)
          continue
        }

        var maxVal: Float = 0.0
        vDSP_maxmgv(baseAddress + start, 1, &maxVal, vDSP_Length(currentBucketSize))

        result.append(maxVal / 32768.0)
      }
    }

    var peak: Float = 0.0
    vDSP_maxv(result, 1, &peak, vDSP_Length(result.count))

    guard peak > 0 else { return result }

    var normalizedResult = [Float](repeating: 0.0, count: result.count)
    var divisor = peak
    vDSP_vsdiv(result, 1, &divisor, &normalizedResult, 1, vDSP_Length(result.count))

    return normalizedResult
  }
}
