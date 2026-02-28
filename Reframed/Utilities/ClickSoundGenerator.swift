@preconcurrency import AVFoundation
import Foundation

enum ClickSoundCategory: CaseIterable, Sendable {
  case click, drop, select, switchSound, toggle

  var label: String {
    switch self {
    case .click: "Click"
    case .drop: "Drop"
    case .select: "Select"
    case .switchSound: "Switch"
    case .toggle: "Toggle"
    }
  }
}

enum ClickSoundStyle: Int, CaseIterable, Identifiable, Codable, Sendable {
  case click001 = 0
  case click002 = 1
  case click003 = 2
  case click004 = 3
  case click005 = 4
  case click8bit = 5
  case clickSoft = 6
  case drop001 = 7
  case drop002 = 8
  case drop003 = 9
  case drop004 = 10
  case select001 = 11
  case select002 = 12
  case select003 = 13
  case select004 = 14
  case select005 = 15
  case select006 = 16
  case select007 = 17
  case select008 = 18
  case switch001 = 19
  case switch002 = 20
  case switch003 = 21
  case switch004 = 22
  case switch005 = 23
  case switch006 = 24
  case switch007 = 25
  case toggle001 = 26
  case toggle002 = 27
  case toggle003 = 28
  case toggle004 = 29

  var id: Int { rawValue }

  var label: String {
    switch self {
    case .click001: "Click 1"
    case .click002: "Click 2"
    case .click003: "Click 3"
    case .click004: "Click 4"
    case .click005: "Click 5"
    case .click8bit: "Click 8-bit"
    case .clickSoft: "Click Soft"
    case .drop001: "Drop 1"
    case .drop002: "Drop 2"
    case .drop003: "Drop 3"
    case .drop004: "Drop 4"
    case .select001: "Select 1"
    case .select002: "Select 2"
    case .select003: "Select 3"
    case .select004: "Select 4"
    case .select005: "Select 5"
    case .select006: "Select 6"
    case .select007: "Select 7"
    case .select008: "Select 8"
    case .switch001: "Switch 1"
    case .switch002: "Switch 2"
    case .switch003: "Switch 3"
    case .switch004: "Switch 4"
    case .switch005: "Switch 5"
    case .switch006: "Switch 6"
    case .switch007: "Switch 7"
    case .toggle001: "Toggle 1"
    case .toggle002: "Toggle 2"
    case .toggle003: "Toggle 3"
    case .toggle004: "Toggle 4"
    }
  }

  var category: ClickSoundCategory {
    switch self {
    case .click001, .click002, .click003, .click004, .click005, .click8bit, .clickSoft: .click
    case .drop001, .drop002, .drop003, .drop004: .drop
    case .select001, .select002, .select003, .select004, .select005, .select006, .select007,
      .select008:
      .select
    case .switch001, .switch002, .switch003, .switch004, .switch005, .switch006, .switch007:
      .switchSound
    case .toggle001, .toggle002, .toggle003, .toggle004: .toggle
    }
  }

  static func styles(for category: ClickSoundCategory) -> [ClickSoundStyle] {
    allCases.filter { $0.category == category }
  }
}

enum ClickSoundGenerator {
  static func generateClickBuffer(
    style: ClickSoundStyle = .click001,
    sampleRate: Double = 44100
  ) -> AVAudioPCMBuffer? {
    let samples = decodeSamples(style: style, sampleRate: sampleRate)
    guard !samples.isEmpty else { return nil }
    let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))
    else { return nil }
    buffer.frameLength = AVAudioFrameCount(samples.count)
    guard let channelData = buffer.floatChannelData?[0] else { return nil }
    samples.withUnsafeBufferPointer { src in
      channelData.update(from: src.baseAddress!, count: samples.count)
    }
    return buffer
  }

  static func generateClickAudioFile(
    at url: URL,
    clickTimes: [(time: Double, button: Int)],
    volume: Float,
    totalDuration: Double,
    style: ClickSoundStyle = .click001,
    sampleRate: Double = 44100
  ) throws {
    let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    let totalFrames = AVAudioFrameCount(sampleRate * totalDuration)
    guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else {
      throw NSError(
        domain: "ClickSoundGenerator",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Failed to create buffer"]
      )
    }
    outputBuffer.frameLength = totalFrames

    guard let outputData = outputBuffer.floatChannelData?[0] else {
      throw NSError(
        domain: "ClickSoundGenerator",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: "No channel data"]
      )
    }

    memset(outputData, 0, Int(totalFrames) * MemoryLayout<Float>.size)

    let clickSamples = decodeSamples(style: style, sampleRate: sampleRate)
    let clickFrames = clickSamples.count

    for click in clickTimes {
      let startFrame = Int(click.time * sampleRate)
      guard startFrame >= 0, startFrame < Int(totalFrames) else { continue }

      for i in 0..<clickFrames {
        let frameIdx = startFrame + i
        guard frameIdx < Int(totalFrames) else { break }
        outputData[frameIdx] += clickSamples[i] * volume
      }
    }

    let file = try AVAudioFile(
      forWriting: url,
      settings: [
        AVFormatIDKey: kAudioFormatMPEG4AAC,
        AVSampleRateKey: sampleRate,
        AVNumberOfChannelsKey: 1,
        AVEncoderBitRateKey: 128000,
      ]
    )
    try file.write(from: outputBuffer)
  }

  private static func decodeSamples(style: ClickSoundStyle, sampleRate: Double) -> [Float] {
    guard let data = Data(base64Encoded: style.base64Data) else { return [] }
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
      "reframed-click-\(UUID().uuidString).mp3"
    )
    defer { try? FileManager.default.removeItem(at: tempURL) }
    do {
      try data.write(to: tempURL)
      let audioFile = try AVAudioFile(forReading: tempURL)
      let sourceFormat = audioFile.processingFormat
      let sourceFrameCount = AVAudioFrameCount(audioFile.length)
      guard
        let sourceBuffer = AVAudioPCMBuffer(
          pcmFormat: sourceFormat,
          frameCapacity: sourceFrameCount
        )
      else { return [] }
      try audioFile.read(into: sourceBuffer)

      let outputFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
      if sourceFormat.sampleRate == sampleRate && sourceFormat.channelCount == 1
        && sourceFormat.commonFormat == .pcmFormatFloat32
      {
        guard let channelData = sourceBuffer.floatChannelData?[0] else { return [] }
        return Array(UnsafeBufferPointer(start: channelData, count: Int(sourceBuffer.frameLength)))
      }

      guard let converter = AVAudioConverter(from: sourceFormat, to: outputFormat) else {
        return []
      }
      let ratio = sampleRate / sourceFormat.sampleRate
      let outputFrames = AVAudioFrameCount(Double(sourceFrameCount) * ratio)
      guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrames)
      else { return [] }

      var error: NSError?
      converter.convert(to: outputBuffer, error: &error) { _, outStatus in
        outStatus.pointee = .haveData
        return sourceBuffer
      }
      if error != nil { return [] }

      guard let outputData = outputBuffer.floatChannelData?[0] else { return [] }
      return Array(UnsafeBufferPointer(start: outputData, count: Int(outputBuffer.frameLength)))
    } catch {
      return []
    }
  }
}
