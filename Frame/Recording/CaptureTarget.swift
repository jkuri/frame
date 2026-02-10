import AppKit
import ScreenCaptureKit

enum CaptureTarget: @unchecked Sendable {
  case region(SelectionRect)
  case window(SCWindow)
  case screen(NSScreen)

  var displayID: CGDirectDisplayID {
    switch self {
    case .region(let selection):
      return selection.displayID
    case .window(let window):
      // Best effort to find the display the window is mostly on
      let windowRect = CGRect(
        x: CGFloat(window.frame.origin.x),
        y: CGFloat(window.frame.origin.y),
        width: CGFloat(window.frame.width),
        height: CGFloat(window.frame.height)
      )
      return NSScreen.displayID(for: CGPoint(x: windowRect.midX, y: windowRect.midY))
    case .screen(let screen):
      return screen.displayID
    }
  }

  var rect: CGRect {
    switch self {
    case .region(let selection):
      return selection.rect
    case .window(let window):
      return CGRect(
        x: CGFloat(window.frame.origin.x),
        y: CGFloat(window.frame.origin.y),
        width: CGFloat(window.frame.width),
        height: CGFloat(window.frame.height)
      )
    case .screen(let screen):
      return screen.frame
    }
  }
}
