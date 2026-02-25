import AVFoundation
import AppKit

extension VideoPreviewContainer {
  override func hitTest(_ point: NSPoint) -> NSView? {
    let loc = convert(point, from: superview)
    if !webcamWrapper.isHidden && webcamWrapper.frame.contains(loc) {
      return self
    }
    return super.hitTest(point)
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

  override func mouseMoved(with event: NSEvent) {
    guard !webcamWrapper.isHidden else {
      NSCursor.arrow.set()
      return
    }
    let loc = convert(event.locationInWindow, from: nil)
    if webcamWrapper.frame.contains(loc) {
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

    if webcamWrapper.frame.contains(loc) && !webcamWrapper.isHidden {
      coord.isDragging = true
      NSCursor.closedHand.set()
      coord.dragStart = loc
      coord.startLayout = coord.cameraLayout.wrappedValue
    } else {
      super.mouseDown(with: event)
    }
  }

  override func mouseDragged(with event: NSEvent) {
    guard let coord = coordinator, coord.isDragging else {
      return super.mouseDragged(with: event)
    }
    let loc = convert(event.locationInWindow, from: nil)
    let canvasRect = AVMakeRect(aspectRatio: currentCanvasSize, insideRect: bounds)
    guard canvasRect.width > 0 && canvasRect.height > 0 else { return }

    let dx = (loc.x - coord.dragStart.x) / canvasRect.width
    let dy = -(loc.y - coord.dragStart.y) / canvasRect.height
    var newX = coord.startLayout.relativeX + dx
    var newY = coord.startLayout.relativeY + dy

    let relW = coord.cameraLayout.wrappedValue.relativeWidth
    let relH: CGFloat = {
      guard let ws = currentWebcamSize else { return relW * 0.75 }
      let aspect = currentCameraAspect.heightToWidthRatio(webcamSize: ws)
      return relW * aspect * (currentCanvasSize.width / max(currentCanvasSize.height, 1))
    }()

    newX = max(0, min(1 - relW, newX))
    newY = max(0, min(1 - relH, newY))

    coord.cameraLayout.wrappedValue.relativeX = newX
    coord.cameraLayout.wrappedValue.relativeY = newY

    currentLayout.relativeX = newX
    currentLayout.relativeY = newY

    isDraggingCamera = true
    let camAspect = currentCameraAspect.heightToWidthRatio(
      webcamSize: currentWebcamSize ?? .zero
    )
    let w = canvasRect.width * currentLayout.relativeWidth
    let h = w * camAspect
    let x = canvasRect.origin.x + canvasRect.width * newX
    let y = canvasRect.origin.y + canvasRect.height * newY

    CATransaction.begin()
    CATransaction.setDisableActions(true)
    webcamWrapper.frame = CGRect(x: x, y: bounds.height - y - h, width: w, height: h)
    if currentCameraShadow > 0 {
      let minDim = min(w, h)
      let scaledRadius = minDim * (currentCameraCornerRadius / 100.0)
      let camBlur = minDim * currentCameraShadow / 2000.0
      webcamWrapper.layer?.shadowRadius = camBlur
      webcamWrapper.layer?.shadowOpacity = 0.6
      webcamWrapper.layer?.shadowPath = CGPath(
        roundedRect: webcamView.bounds,
        cornerWidth: scaledRadius,
        cornerHeight: scaledRadius,
        transform: nil
      )
    }
    CATransaction.commit()
  }

  override func mouseUp(with event: NSEvent) {
    let wasDragging = coordinator?.isDragging == true
    coordinator?.isDragging = false
    isDraggingCamera = false
    if wasDragging {
      layoutAll()
      let loc = convert(event.locationInWindow, from: nil)
      if webcamWrapper.frame.contains(loc) {
        NSCursor.openHand.set()
      } else {
        NSCursor.arrow.set()
      }
    }
    super.mouseUp(with: event)
  }
}
