import AppKit
import ScreenCaptureKit

enum CaptureTarget: @unchecked Sendable {
  case region(SelectionRect)
  case window(SCWindow)

  var displayID: CGDirectDisplayID {
    switch self {
    case .region(let selection):
      return selection.displayID
    case .window(let window):
      let windowRect = CGRect(
        x: CGFloat(window.frame.origin.x),
        y: CGFloat(window.frame.origin.y),
        width: CGFloat(window.frame.width),
        height: CGFloat(window.frame.height)
      )
      return NSScreen.displayID(for: CGPoint(x: windowRect.midX, y: windowRect.midY))
    }
  }
}
