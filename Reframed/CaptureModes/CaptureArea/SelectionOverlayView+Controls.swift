import AppKit
import SwiftUI

extension SelectionOverlayView {
  func applyExternalRect(_ newRect: CGRect) {
    selectionRect = newRect.clamped(to: bounds)
    needsDisplay = true
    updateControlsPanel()
  }

  func confirmSelection() {
    guard let rect = selectionRect, rect.width >= 10, rect.height >= 10 else {
      session.cancelSelection()
      return
    }

    guard let window = self.window else {
      session.cancelSelection()
      return
    }

    let windowRect = convert(rect, to: nil)
    let screenRect = window.convertToScreen(windowRect)
    let midPoint = CGPoint(x: screenRect.midX, y: screenRect.midY)
    let displayID = NSScreen.screens.first { $0.frame.contains(midPoint) }?.displayID ?? CGMainDisplayID()

    let selection = SelectionRect(rect: screenRect, displayID: displayID)
    session.confirmSelection(selection)
  }

  func updateControlsPanel() {
    guard let rect = selectionRect else {
      controlsHost?.isHidden = true
      return
    }

    let isFirstCreate = controlsHost == nil
    if isFirstCreate {
      let view = CaptureAreaView(session: session)
      let hosting = NSHostingView(rootView: view)
      addSubview(hosting)
      controlsHost = hosting
    }

    guard let hosting = controlsHost else { return }

    if isFirstCreate {
      DispatchQueue.main.async {
        NotificationCenter.default.post(name: .selectionRectChanged, object: NSValue(rect: rect))
      }
    } else {
      NotificationCenter.default.post(name: .selectionRectChanged, object: NSValue(rect: rect))
    }

    let panelSize = hosting.intrinsicContentSize
    hosting.setFrameSize(panelSize)

    var panelX = rect.midX - panelSize.width / 2
    var panelY = rect.minY - panelSize.height - 16

    if panelY < bounds.minY + 8 {
      panelY = rect.maxY + 16
    }

    panelX = max(bounds.minX + 8, min(panelX, bounds.maxX - panelSize.width - 8))
    panelY = max(bounds.minY + 8, min(panelY, bounds.maxY - panelSize.height - 8))

    hosting.frame.origin = CGPoint(x: panelX, y: panelY)
    hosting.isHidden = false
  }
}
