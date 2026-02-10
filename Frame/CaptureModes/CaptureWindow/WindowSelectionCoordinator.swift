import AppKit
import ScreenCaptureKit

@MainActor
final class WindowSelectionCoordinator {
  private var overlayWindow: WindowSelectionOverlay?
  private var highlightWindow: RecordingBorderWindow?

  func beginSelection(session: SessionState) {
    let window = WindowSelectionOverlay(session: session)
    overlayWindow = window
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  func highlight(window: SCWindow?) {
    guard let window = window else {
      highlightWindow?.orderOut(nil)
      highlightWindow = nil
      return
    }

    // Convert SCWindow frame (Top-Left global) to Cocoa frame (Bottom-Left global)
    // Cocoa (0,0) is bottom-left of primary screen.
    // SCWindow (0,0) is top-left of primary screen.
    let mainScreenHeight = NSScreen.screens.first?.frame.height ?? 0
    let cocoaY = mainScreenHeight - CGFloat(window.frame.origin.y) - CGFloat(window.frame.height)

    let rect = CGRect(
      x: CGFloat(window.frame.origin.x),
      y: cocoaY,
      width: CGFloat(window.frame.width),
      height: CGFloat(window.frame.height)
    )

    if let highlightWindow = highlightWindow {
      highlightWindow.setFrame(rect.insetBy(dx: -2, dy: -2), display: true)
    } else {
      let hw = RecordingBorderWindow(screenRect: rect)
      hw.level = .floating // Ensure it's above the overlay
      highlightWindow = hw
      hw.orderFrontRegardless()
    }
  }

  func destroyOverlay() {
    overlayWindow?.orderOut(nil)
    overlayWindow?.contentView = nil
    overlayWindow = nil

    highlightWindow?.orderOut(nil)
    highlightWindow = nil
  }
}
