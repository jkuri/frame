import Foundation
import Logging

extension EditorState {
  var captionAudioURL: URL? {
    switch captionAudioSource {
    case .microphone: result.microphoneAudioURL
    case .system: result.systemAudioURL
    }
  }

  func generateCaptions() {
    guard let audioURL = captionAudioURL else { return }
    guard let model = WhisperModel(rawValue: captionModel) else { return }
    guard let modelPath = WhisperModelManager.shared.modelPath(for: model) else { return }

    transcriptionTask?.cancel()
    isTranscribing = true
    transcriptionProgress = 0

    let language = captionLanguage.whisperCode
    let state = self
    transcriptionTask = Task {
      do {
        let segments = try await TranscriptionService.transcribe(
          audioURL: audioURL,
          model: model,
          modelPath: modelPath,
          language: language,
          onProgress: { progress in
            state.transcriptionProgress = progress
          }
        )
        try Task.checkCancellation()
        state.captionSegments = segments
        state.captionsEnabled = true
        state.isTranscribing = false
        state.transcriptionProgress = 1.0
        state.scheduleSave()
        state.history.pushSnapshot(state.createSnapshot())
      } catch is CancellationError {
        state.isTranscribing = false
      } catch {
        state.logger.error("Transcription failed: \(error)")
        state.isTranscribing = false
      }
    }
  }

  func cancelTranscription() {
    transcriptionTask?.cancel()
    transcriptionTask = nil
    isTranscribing = false
    transcriptionProgress = 0
  }

  func clearCaptions() {
    captionSegments = []
    captionsEnabled = false
    scheduleSave()
    history.pushSnapshot(createSnapshot())
  }

  func captionAtTime(_ time: Double) -> CaptionSegment? {
    captionSegments.first { time >= $0.startSeconds && time < $0.endSeconds }
  }

  func visibleCaptionText(at time: Double) -> String? {
    guard captionsEnabled, let segment = captionAtTime(time) else { return nil }

    let words: [String]
    if let segmentWords = segment.words, !segmentWords.isEmpty {
      words = segmentWords.map(\.word)
    } else {
      words = segment.text.split(separator: " ").map(String.init)
    }

    guard !words.isEmpty else { return segment.text }

    let maxWords = captionMaxWordsPerLine
    if words.count <= maxWords {
      return words.joined(separator: " ")
    }

    var lines: [String] = []
    var i = 0
    while i < words.count {
      let chunk = words[i..<min(i + maxWords, words.count)]
      lines.append(chunk.joined(separator: " "))
      i += maxWords
    }

    let totalLines = lines.count
    let windowStart = time - segment.startSeconds
    let segmentDuration = segment.endSeconds - segment.startSeconds
    guard segmentDuration > 0 else { return lines.prefix(2).joined(separator: "\n") }

    let linesPerWindow = 2
    let windowCount = max(1, Int(ceil(Double(totalLines) / Double(linesPerWindow))))
    let windowDuration = segmentDuration / Double(windowCount)
    let windowIndex = min(Int(windowStart / windowDuration), windowCount - 1)
    let lineStart = windowIndex * linesPerWindow
    let visibleLines = lines[lineStart..<min(lineStart + linesPerWindow, totalLines)]
    return visibleLines.joined(separator: "\n")
  }
}
