import AppKit

struct SelectionRect: Sendable {
  let rect: CGRect
  let displayID: CGDirectDisplayID

  var screenCaptureKitRect: CGRect {
    let screenHeight = CGFloat(CGDisplayPixelsHigh(displayID))
    return CGRect(
      x: rect.origin.x,
      y: screenHeight - rect.origin.y - rect.height,
      width: rect.width,
      height: rect.height
    )
  }

  var backingScaleFactor: CGFloat {
    NSScreen.screen(for: displayID)?.backingScaleFactor ?? 2.0
  }

  var pixelWidth: Int {
    let w = Int(rect.width * backingScaleFactor)
    return w & ~1
  }

  var pixelHeight: Int {
    let h = Int(rect.height * backingScaleFactor)
    return h & ~1
  }
}
