import AppKit
import SwiftUI

@MainActor
final class WindowSelectionOverlay: NSWindow {
  init(session: SessionState) {
    // Cover all screens
    let frame = NSScreen.unionFrame

    super.init(
      contentRect: frame,
      styleMask: .borderless,
      backing: .buffered,
      defer: false
    )

    isOpaque = false
    backgroundColor = .clear
    level = .screenSaver
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    ignoresMouseEvents = false
    acceptsMouseMovedEvents = true
    hasShadow = false

    let view = WindowSelectionView(session: session)
    let hostingView = NSHostingView(rootView: view)
    hostingView.frame = frame
    contentView = hostingView
  }

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }
}
