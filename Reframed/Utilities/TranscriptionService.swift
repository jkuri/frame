import AVFoundation
import Foundation
import WhisperKit

enum TranscriptionService {
  static func transcribe(
    audioURL: URL,
    model: WhisperModel,
    modelPath: URL,
    language: String? = nil,
    onProgress: (@MainActor @Sendable (Double) -> Void)? = nil
  ) async throws -> [CaptionSegment] {
    await onProgress?(0.02)

    let asset = AVURLAsset(url: audioURL)
    let duration = try await asset.load(.duration)
    let audioDurationSeconds = CMTimeGetSeconds(duration)
    let windowSeconds: Double = 30.0
    let totalWindows = max(1, Int(ceil(audioDurationSeconds / windowSeconds)))

    await onProgress?(0.05)

    let modelsBase = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(".reframed")
    let computeOptions = ModelComputeOptions(
      melCompute: .all,
      audioEncoderCompute: .all,
      textDecoderCompute: .all,
      prefillCompute: .all
    )
    let config = WhisperKitConfig(
      downloadBase: modelsBase,
      modelFolder: modelPath.path,
      computeOptions: computeOptions,
      verbose: false,
      logLevel: .none,
      load: true,
      download: false
    )
    let whisperKit = try await WhisperKit(config)

    await onProgress?(0.15)

    let workerCount = max(16, ProcessInfo.processInfo.activeProcessorCount)
    var options = DecodingOptions(
      temperatureFallbackCount: 2,
      skipSpecialTokens: true,
      wordTimestamps: true,
      compressionRatioThreshold: 2.8,
      logProbThreshold: -1.5,
      noSpeechThreshold: 0.5,
      concurrentWorkerCount: workerCount,
      chunkingStrategy: .vad
    )
    if let language {
      options.language = language
    }

    let progressCallback = onProgress
    let expectedWindows = totalWindows
    nonisolated(unsafe) var highWaterMark: Double = 0.15
    let callback: TranscriptionCallback = { (progress: TranscriptionProgress) -> Bool? in
      let windowProgress = Double(progress.windowId + 1) / Double(expectedWindows)
      let overall = min(0.15 + windowProgress * 0.8, 0.95)
      guard overall > highWaterMark else { return nil }
      highWaterMark = overall
      let value = overall
      Task { @MainActor in
        progressCallback?(value)
      }
      return nil
    }

    let results = try await whisperKit.transcribe(
      audioPath: audioURL.path,
      decodeOptions: options,
      callback: callback
    )

    await onProgress?(0.95)

    var segments: [CaptionSegment] = []
    for result in results {
      for segment in result.segments {
        let words: [CaptionWord]? = segment.words?.map { w in
          CaptionWord(
            word: stripSpecialTokens(w.word).trimmingCharacters(in: CharacterSet.whitespaces),
            startSeconds: Double(w.start),
            endSeconds: Double(w.end)
          )
        }

        let cleanText = stripSpecialTokens(segment.text)
          .trimmingCharacters(in: CharacterSet.whitespaces)
        guard !cleanText.isEmpty else { continue }

        let captionSegment = CaptionSegment(
          startSeconds: Double(segment.start),
          endSeconds: Double(segment.end),
          text: cleanText,
          words: words?.filter { !$0.word.isEmpty }
        )
        segments.append(captionSegment)
      }
    }

    await onProgress?(1.0)
    return mergeShortSegments(segments)
  }

  private static func mergeShortSegments(_ segments: [CaptionSegment]) -> [CaptionSegment] {
    guard segments.count > 1 else { return segments }

    let minWordCount = 4
    let maxGap = 2.0

    var merged: [CaptionSegment] = []
    for segment in segments {
      let wordCount = segment.text.split(separator: " ").count
      if wordCount < minWordCount,
        let last = merged.last,
        segment.startSeconds - last.endSeconds < maxGap
      {
        let combinedText = last.text + " " + segment.text
        let combinedWords: [CaptionWord]? = {
          guard let lw = last.words, let sw = segment.words else { return last.words ?? segment.words }
          return lw + sw
        }()
        merged[merged.count - 1] = CaptionSegment(
          id: last.id,
          startSeconds: last.startSeconds,
          endSeconds: segment.endSeconds,
          text: combinedText,
          words: combinedWords
        )
      } else {
        merged.append(segment)
      }
    }
    return merged
  }

  private static func stripSpecialTokens(_ text: String) -> String {
    text.replacingOccurrences(
      of: "<\\|[^|]+\\|>",
      with: "",
      options: .regularExpression
    )
  }
}
