import AppKit
import SwiftUI

enum FrameColors {
  static let overlayBackground = NSColor.black.withAlphaComponent(0.5)
  static let selectionBorder = NSColor(white: 0.55, alpha: 0.6)
  static let selectionGrid = NSColor(white: 0.55, alpha: 0.3)
  static let handleFill = NSColor(white: 0.15, alpha: 0.9)
  static let handleStroke = NSColor(white: 0.7, alpha: 0.8)
  static let crosshair = NSColor.white.withAlphaComponent(0.3)

  static let panelBackground = Color(white: 0.1)
  static let fieldBackground = Color.white.opacity(0.08)
  static let dimLabel = Color.white.opacity(0.4)
  static let textSelection = Color(white: 0.35)
}
