import AVFoundation
import Foundation

@MainActor
final class ClickSoundPlayer {
  private var engine: AVAudioEngine?
  private var playerNode: AVAudioPlayerNode?
  private var clickBuffer: AVAudioPCMBuffer?
  private var playedClicks: Set<String> = []
  private var currentStyle: ClickSoundStyle = .click001
  private var currentVolume: Float = 0.5

  var isSetup: Bool { engine != nil }

  func setup() {
    guard engine == nil else { return }
    let eng = AVAudioEngine()
    let node = AVAudioPlayerNode()
    eng.attach(node)

    let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
    eng.connect(node, to: eng.mainMixerNode, format: format)

    do {
      try eng.start()
    } catch {
      return
    }

    engine = eng
    playerNode = node
    clickBuffer = ClickSoundGenerator.generateClickBuffer(style: currentStyle)
  }

  func updateStyle(_ style: ClickSoundStyle, volume: Float) {
    let styleChanged = currentStyle != style
    currentVolume = volume
    if styleChanged {
      currentStyle = style
      clickBuffer = ClickSoundGenerator.generateClickBuffer(style: style)
    }
  }

  func playClick(at time: Double, button: Int, volume: Float) {
    let key = String(format: "%.3f-%d", time, button)
    guard !playedClicks.contains(key) else { return }
    playedClicks.insert(key)

    guard let node = playerNode, let buffer = clickBuffer, let eng = engine else { return }

    if !eng.isRunning {
      try? eng.start()
    }

    eng.mainMixerNode.outputVolume = volume
    node.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    if !node.isPlaying {
      node.play()
    }
  }

  func reset() {
    playedClicks.removeAll()
  }

  func teardown() {
    playerNode?.stop()
    engine?.stop()
    engine = nil
    playerNode = nil
    clickBuffer = nil
    playedClicks.removeAll()
  }
}
