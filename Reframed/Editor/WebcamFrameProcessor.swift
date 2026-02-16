import AVFoundation
import CoreImage
import Logging
import Vision

private let videoOutputAttributes: [String: any Sendable] = [
  kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
]

@MainActor
final class WebcamFrameProcessor {
  private let player: AVPlayer
  private let videoOutput: AVPlayerItemVideoOutput
  private var displayTimer: Timer?
  private let processingQueue = DispatchQueue(label: "eu.jankuri.reframed.webcam-processor", qos: .userInteractive)
  private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

  private var isProcessing = false
  private var lastPixelBuffer: CVPixelBuffer?
  private var needsReprocess = false
  var onFrameReady: (@MainActor @Sendable (CGImage) -> Void)?

  var backgroundStyle: CameraBackgroundStyle = .none
  var backgroundImageData: Data?
  var cameraMirrored: Bool = false

  init(player: AVPlayer) {
    self.player = player
    self.videoOutput = AVPlayerItemVideoOutput(outputSettings: videoOutputAttributes)
  }

  func start() {
    guard let item = player.currentItem else { return }
    if !item.outputs.contains(where: { $0 === videoOutput }) {
      item.add(videoOutput)
    }
    displayTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.pollFrame()
      }
    }
  }

  func stop() {
    displayTimer?.invalidate()
    displayTimer = nil
    lastPixelBuffer = nil
    if let item = player.currentItem, item.outputs.contains(where: { $0 === videoOutput }) {
      item.remove(videoOutput)
    }
  }

  func reprocessCurrentFrame() {
    if isProcessing {
      needsReprocess = true
      return
    }
    guard let pixelBuffer = lastPixelBuffer else { return }
    submitProcessing(pixelBuffer: pixelBuffer)
  }

  private func pollFrame() {
    let currentTime = player.currentTime()
    if videoOutput.hasNewPixelBuffer(forItemTime: currentTime),
      let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil)
    {
      lastPixelBuffer = pixelBuffer
      if !isProcessing {
        submitProcessing(pixelBuffer: pixelBuffer)
      }
    }
  }

  private func submitProcessing(pixelBuffer: CVPixelBuffer) {
    isProcessing = true
    needsReprocess = false
    let style = backgroundStyle
    let bgImageData = backgroundImageData
    let mirrored = cameraMirrored
    let ctx = ciContext
    let callback = onFrameReady

    nonisolated(unsafe) let unsafePixelBuffer = pixelBuffer
    processingQueue.async { [weak self] in
      let result = Self.processFrame(
        pixelBuffer: unsafePixelBuffer,
        style: style,
        backgroundImageData: bgImageData,
        mirrored: mirrored,
        ciContext: ctx
      )
      DispatchQueue.main.async {
        guard let self else { return }
        MainActor.assumeIsolated {
          self.isProcessing = false
          if let image = result {
            callback?(image)
          }
          if self.needsReprocess {
            self.reprocessCurrentFrame()
          }
        }
      }
    }
  }

  nonisolated private static func processFrame(
    pixelBuffer: CVPixelBuffer,
    style: CameraBackgroundStyle,
    backgroundImageData: Data?,
    mirrored: Bool,
    ciContext: CIContext
  ) -> CGImage? {
    let request = VNGeneratePersonSegmentationRequest()
    request.qualityLevel = .balanced

    let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
    try? handler.perform([request])

    guard let maskBuffer = request.results?.first?.pixelBuffer else { return nil }

    let foreground = CIImage(cvPixelBuffer: pixelBuffer)
    let maskImage = CIImage(cvPixelBuffer: maskBuffer).resized(to: foreground.extent.size)
    let size = foreground.extent.size

    let background: CIImage
    switch style {
    case .none:
      return nil
    case .transparent:
      background = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0)).cropped(to: foreground.extent)
    case .solidColor(let color):
      background = CIImage(color: CIColor(red: color.r, green: color.g, blue: color.b, alpha: color.a)).cropped(to: foreground.extent)
    case .gradient(let id):
      if let grad = CIImage.renderGradientCIImage(presetId: id, size: size) {
        background = grad
      } else {
        background = CIImage(color: CIColor.black).cropped(to: foreground.extent)
      }
    case .image:
      if let data = backgroundImageData, let bgImage = CIImage(data: data) {
        background = bgImage.resizedToFill(size)
      } else {
        background = CIImage(color: CIColor.black).cropped(to: foreground.extent)
      }
    }

    guard let blendFilter = CIFilter(name: "CIBlendWithMask") else { return nil }
    blendFilter.setValue(foreground, forKey: kCIInputImageKey)
    blendFilter.setValue(background, forKey: kCIInputBackgroundImageKey)
    blendFilter.setValue(maskImage, forKey: kCIInputMaskImageKey)

    guard var output = blendFilter.outputImage else { return nil }

    if mirrored {
      output =
        output
        .transformed(by: CGAffineTransform(scaleX: -1, y: 1))
        .transformed(by: CGAffineTransform(translationX: size.width, y: 0))
    }

    return ciContext.createCGImage(output, from: output.extent)
  }
}
