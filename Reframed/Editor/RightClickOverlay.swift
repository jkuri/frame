import SwiftUI

struct RightClickOverlay: NSViewRepresentable {
  let action: () -> Void

  func makeNSView(context: Context) -> RightClickNSView {
    RightClickNSView(action: action)
  }

  func updateNSView(_ nsView: RightClickNSView, context: Context) {
    nsView.action = action
  }

  class RightClickNSView: NSView {
    var action: () -> Void

    init(action: @escaping () -> Void) {
      self.action = action
      super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError()
    }

    override func rightMouseDown(with event: NSEvent) {
      action()
    }
  }
}
