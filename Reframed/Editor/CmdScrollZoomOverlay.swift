import AppKit
import SwiftUI

struct CmdScrollZoomOverlay: NSViewRepresentable {
  let onZoom: (CGFloat, CGFloat) -> Void

  func makeNSView(context: Context) -> CmdScrollZoomNSView {
    CmdScrollZoomNSView(onZoom: onZoom)
  }

  func updateNSView(_ nsView: CmdScrollZoomNSView, context: Context) {
    nsView.onZoom = onZoom
  }

  class CmdScrollZoomNSView: NSView {
    var onZoom: (CGFloat, CGFloat) -> Void

    init(onZoom: @escaping (CGFloat, CGFloat) -> Void) {
      self.onZoom = onZoom
      super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError()
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
      guard NSEvent.modifierFlags.contains(.command) else { return nil }
      return super.hitTest(point)
    }

    override func scrollWheel(with event: NSEvent) {
      guard event.modifierFlags.contains(.command) else {
        super.scrollWheel(with: event)
        return
      }
      let cursorX = convert(event.locationInWindow, from: nil).x
      onZoom(event.scrollingDeltaY, cursorX)
    }
  }
}
