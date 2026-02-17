import Foundation

enum AudioNoiseReducer {
  static func processFile(inputURL: URL, outputURL: URL, intensity: Float = 0.5) async throws {
    try await RNNoiseProcessor.processFile(
      inputURL: inputURL,
      outputURL: outputURL,
      intensity: intensity
    )
  }
}
