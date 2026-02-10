import AVFoundation
import AppKit
import SwiftUI

struct VideoPreviewView: NSViewRepresentable {
  let screenPlayer: AVPlayer
  let webcamPlayer: AVPlayer?
  @Binding var pipLayout: PiPLayout
  let webcamSize: CGSize?
  let screenSize: CGSize

  func makeNSView(context: Context) -> VideoPreviewContainer {
    let container = VideoPreviewContainer()
    container.screenPlayerLayer.player = screenPlayer
    if let webcam = webcamPlayer {
      container.webcamPlayerLayer.player = webcam
      container.webcamPlayerLayer.isHidden = false
    }
    container.coordinator = context.coordinator
    return container
  }

  func updateNSView(_ nsView: VideoPreviewContainer, context: Context) {
    nsView.updatePiPLayout(pipLayout, webcamSize: webcamSize, screenSize: screenSize)
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(pipLayout: $pipLayout, screenSize: screenSize, webcamSize: webcamSize)
  }

  final class Coordinator {
    var pipLayout: Binding<PiPLayout>
    let screenSize: CGSize
    let webcamSize: CGSize?
    var isDragging = false
    var isResizing = false
    var dragStart: CGPoint = .zero
    var startLayout: PiPLayout = PiPLayout()

    init(pipLayout: Binding<PiPLayout>, screenSize: CGSize, webcamSize: CGSize?) {
      self.pipLayout = pipLayout
      self.screenSize = screenSize
      self.webcamSize = webcamSize
    }
  }
}

final class VideoPreviewContainer: NSView {
  let screenPlayerLayer = AVPlayerLayer()
  let webcamPlayerLayer = AVPlayerLayer()
  private let webcamView = WebcamPiPView()
  private let resizeGrip = ResizeGripView()
  var coordinator: VideoPreviewView.Coordinator?
  private let handleSize: CGFloat = 20
  private var currentLayout = PiPLayout()
  private var currentWebcamSize: CGSize?
  private var currentScreenSize: CGSize = .zero
  private var trackingArea: NSTrackingArea?

  override init(frame: NSRect) {
    super.init(frame: frame)
    wantsLayer = true
    layer?.backgroundColor = NSColor.black.cgColor

    screenPlayerLayer.videoGravity = .resizeAspect
    layer?.addSublayer(screenPlayerLayer)

    webcamView.wantsLayer = true
    webcamView.layer?.cornerRadius = 8
    webcamView.layer?.masksToBounds = true
    webcamView.layer?.borderWidth = 1
    webcamView.layer?.borderColor = NSColor.white.withAlphaComponent(0.3).cgColor
    webcamPlayerLayer.videoGravity = .resizeAspectFill
    webcamView.layer?.addSublayer(webcamPlayerLayer)
    webcamPlayerLayer.isHidden = true
    addSubview(webcamView)
    addSubview(resizeGrip)
  }

  required init?(coder: NSCoder) { nil }

  override func hitTest(_ point: NSPoint) -> NSView? {
    let loc = convert(point, from: superview)
    if !webcamView.isHidden && (resizeGrip.frame.contains(loc) || webcamView.frame.contains(loc)) {
      return self
    }
    return super.hitTest(point)
  }

  override func layout() {
    super.layout()
    screenPlayerLayer.frame = bounds
    layoutWebcamView()
  }

  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    if let existing = trackingArea {
      removeTrackingArea(existing)
    }
    let area = NSTrackingArea(
      rect: bounds,
      options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
      owner: self
    )
    addTrackingArea(area)
    trackingArea = area
  }

  func updatePiPLayout(_ layout: PiPLayout, webcamSize: CGSize?, screenSize: CGSize) {
    currentLayout = layout
    currentWebcamSize = webcamSize
    currentScreenSize = screenSize
    layoutWebcamView()
  }

  private func layoutWebcamView() {
    guard let ws = currentWebcamSize, webcamPlayerLayer.player != nil else {
      webcamView.isHidden = true
      resizeGrip.isHidden = true
      return
    }
    webcamView.isHidden = false

    let videoRect = AVMakeRect(aspectRatio: currentScreenSize, insideRect: bounds)
    let aspect = ws.height / max(ws.width, 1)
    let w = videoRect.width * currentLayout.relativeWidth
    let h = w * aspect
    let x = videoRect.origin.x + videoRect.width * currentLayout.relativeX
    let y = videoRect.origin.y + videoRect.height * currentLayout.relativeY

    webcamView.frame = CGRect(x: x, y: bounds.height - y - h, width: w, height: h)
    webcamPlayerLayer.frame = webcamView.bounds

    resizeGrip.frame = CGRect(
      x: webcamView.frame.maxX - handleSize,
      y: webcamView.frame.minY,
      width: handleSize,
      height: handleSize
    )
    resizeGrip.isHidden = false
  }

  private func resizeHandleRect() -> CGRect {
    CGRect(
      x: webcamView.frame.maxX - handleSize,
      y: webcamView.frame.minY,
      width: handleSize,
      height: handleSize
    )
  }

  override func mouseMoved(with event: NSEvent) {
    guard !webcamView.isHidden else {
      NSCursor.arrow.set()
      return
    }
    let loc = convert(event.locationInWindow, from: nil)
    if resizeHandleRect().contains(loc) {
      NSCursor.resizeLeftRight.set()
    } else if webcamView.frame.contains(loc) {
      NSCursor.openHand.set()
    } else {
      NSCursor.arrow.set()
    }
  }

  override func mouseExited(with event: NSEvent) {
    NSCursor.arrow.set()
  }

  override func mouseDown(with event: NSEvent) {
    guard let coord = coordinator else { return super.mouseDown(with: event) }
    let loc = convert(event.locationInWindow, from: nil)

    if webcamView.frame.contains(loc) && !webcamView.isHidden {
      if resizeHandleRect().contains(loc) {
        coord.isResizing = true
        NSCursor.resizeLeftRight.set()
      } else {
        coord.isDragging = true
        NSCursor.closedHand.set()
      }
      coord.dragStart = loc
      coord.startLayout = coord.pipLayout.wrappedValue
    } else {
      super.mouseDown(with: event)
    }
  }

  override func mouseDragged(with event: NSEvent) {
    guard let coord = coordinator else { return super.mouseDragged(with: event) }
    let loc = convert(event.locationInWindow, from: nil)
    let videoRect = AVMakeRect(aspectRatio: coord.screenSize, insideRect: bounds)
    guard videoRect.width > 0 && videoRect.height > 0 else { return }

    if coord.isDragging {
      let dx = (loc.x - coord.dragStart.x) / videoRect.width
      let dy = -(loc.y - coord.dragStart.y) / videoRect.height
      var newX = coord.startLayout.relativeX + dx
      var newY = coord.startLayout.relativeY + dy

      let relW = coord.pipLayout.wrappedValue.relativeWidth
      let relH: CGFloat = {
        guard let ws = coord.webcamSize else { return relW * 0.75 }
        let aspect = ws.height / max(ws.width, 1)
        return relW * aspect * (coord.screenSize.width / max(coord.screenSize.height, 1))
      }()

      newX = max(0, min(1 - relW, newX))
      newY = max(0, min(1 - relH, newY))

      let snapDistX: CGFloat = 20 / videoRect.width
      let snapDistY: CGFloat = 20 / videoRect.height
      if newX < snapDistX { newX = 0.02 }
      if newX > 1 - relW - snapDistX { newX = 1 - relW - 0.02 }
      if newY < snapDistY { newY = 0.02 }
      if newY > 1 - relH - snapDistY { newY = 1 - relH - 0.02 }

      coord.pipLayout.wrappedValue.relativeX = newX
      coord.pipLayout.wrappedValue.relativeY = newY
    } else if coord.isResizing {
      let dx = (loc.x - coord.dragStart.x) / videoRect.width
      var newW = coord.startLayout.relativeWidth + dx
      newW = max(0.1, min(0.5, newW))
      coord.pipLayout.wrappedValue.relativeWidth = newW
    }
  }

  override func mouseUp(with event: NSEvent) {
    let wasInteracting = coordinator?.isDragging == true || coordinator?.isResizing == true
    coordinator?.isDragging = false
    coordinator?.isResizing = false
    if wasInteracting {
      let loc = convert(event.locationInWindow, from: nil)
      if resizeHandleRect().contains(loc) {
        NSCursor.resizeLeftRight.set()
      } else if webcamView.frame.contains(loc) {
        NSCursor.openHand.set()
      } else {
        NSCursor.arrow.set()
      }
    }
    super.mouseUp(with: event)
  }
}

private final class WebcamPiPView: NSView {
  override var isFlipped: Bool { true }
}

private final class ResizeGripView: NSView {
  override init(frame: NSRect) {
    super.init(frame: frame)
    wantsLayer = true
    layer?.backgroundColor = NSColor.clear.cgColor
  }

  required init?(coder: NSCoder) { nil }

  override func draw(_ dirtyRect: NSRect) {
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    let color = NSColor.white.withAlphaComponent(0.6).cgColor
    ctx.setStrokeColor(color)
    ctx.setLineWidth(1.5)
    ctx.setLineCap(.round)

    let inset: CGFloat = 4
    let spacing: CGFloat = 4

    for i in 0..<3 {
      let offset = CGFloat(i) * spacing
      let startX = bounds.maxX - inset - offset
      let startY = bounds.minY + inset
      let endX = bounds.maxX - inset
      let endY = bounds.minY + inset + offset
      ctx.move(to: CGPoint(x: startX, y: startY))
      ctx.addLine(to: CGPoint(x: endX, y: endY))
    }
    ctx.strokePath()
  }
}
