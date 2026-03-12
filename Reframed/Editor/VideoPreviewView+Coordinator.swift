import AppKit
import SwiftUI

extension VideoPreviewView {
  final class Coordinator {
    var cameraLayout: Binding<CameraLayout>
    let screenSize: CGSize
    var canvasSize: CGSize
    let webcamSize: CGSize?
    var isDragging = false
    var dragStart: CGPoint = .zero
    var startLayout: CameraLayout = CameraLayout()
    var lastProcessedTime: Double = -1
    var clickSoundPlayer: ClickSoundPlayer?

    init(cameraLayout: Binding<CameraLayout>, screenSize: CGSize, canvasSize: CGSize, webcamSize: CGSize?) {
      self.cameraLayout = cameraLayout
      self.screenSize = screenSize
      self.canvasSize = canvasSize
      self.webcamSize = webcamSize
    }

    deinit {
      let player = clickSoundPlayer
      if player != nil {
        Task { @MainActor in
          player?.teardown()
        }
      }
    }
  }
}
