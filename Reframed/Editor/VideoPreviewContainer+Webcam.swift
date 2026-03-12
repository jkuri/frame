import AVFoundation
import AppKit

extension VideoPreviewContainer {
  func setupWebcamOutput(for player: AVPlayer) {
    guard webcamOutput == nil else { return }
    let formatKey = kCVPixelBufferPixelFormatTypeKey as String
    let formatValue = Int(kCVPixelFormatType_32BGRA)
    let output = AVPlayerItemVideoOutput(pixelBufferAttributes: [formatKey: formatValue])
    output.setDelegate(self, queue: .main)
    player.currentItem?.add(output)
    webcamOutput = output
    output.requestNotificationOfMediaDataChange(withAdvanceInterval: 0.0)
  }

  func teardownWebcamOutput() {
    if let output = webcamOutput, let item = webcamPlayerLayer.player?.currentItem {
      item.remove(output)
    }
    webcamOutput = nil
    processedWebcamLayer.contents = nil
    processedWebcamLayer.isHidden = true
    webcamPlayerLayer.isHidden = false
    lastProcessedWebcamTime = -1
  }

  func processCurrentWebcamFrame() {
    guard currentCameraBackgroundStyle != .none,
      let output = webcamOutput,
      let player = webcamPlayerLayer.player
    else {
      processedWebcamLayer.isHidden = true
      webcamPlayerLayer.isHidden = false
      return
    }

    guard !isProcessingWebcamFrame else { return }

    let time = player.currentTime()
    let seconds = CMTimeGetSeconds(time)
    guard seconds.isFinite else { return }

    let itemTime = output.itemTime(forHostTime: CACurrentMediaTime())
    guard output.hasNewPixelBuffer(forItemTime: itemTime) || abs(seconds - lastProcessedWebcamTime) > 0.01 else {
      return
    }

    var backgroundCGImage: CGImage?
    if case .image = currentCameraBackgroundStyle, let nsImage = currentCameraBackgroundImage {
      var rect = CGRect(origin: .zero, size: nsImage.size)
      backgroundCGImage = nsImage.cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }

    guard let pixelBuffer = output.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) else { return }
    lastProcessedWebcamTime = seconds
    isProcessingWebcamFrame = true

    let style = currentCameraBackgroundStyle
    let processor = segmentationProcessor
    let bgImage = backgroundCGImage
    nonisolated(unsafe) let buffer = pixelBuffer

    segmentationQueue.async { [weak self] in
      let processed = processor.processFrame(
        webcamBuffer: buffer,
        style: style,
        backgroundCGImage: bgImage
      )
      DispatchQueue.main.async {
        guard let self else { return }
        self.isProcessingWebcamFrame = false
        guard let processed else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.processedWebcamLayer.contents = processed
        self.processedWebcamLayer.isHidden = false
        self.syncProcessedWebcamLayer()
        self.webcamPlayerLayer.isHidden = true
        CATransaction.commit()
      }
    }
  }
}

extension VideoPreviewContainer: AVPlayerItemOutputPullDelegate {
  nonisolated func outputMediaDataWillChange(_ sender: AVPlayerItemOutput) {
    DispatchQueue.main.async { [weak self] in
      self?.processCurrentWebcamFrame()
    }
  }
}
