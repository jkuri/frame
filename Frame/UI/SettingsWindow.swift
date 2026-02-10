import AppKit
import SwiftUI

@MainActor
final class SettingsWindow {
  static let shared = SettingsWindow()

  private var window: NSWindow?

  func show() {
    if let window {
      window.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
      return
    }

    let settingsView = SettingsView()
    let hostingView = NSHostingView(rootView: settingsView)

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 700, height: 640),
      styleMask: [.titled, .closable, .miniaturizable],
      backing: .buffered,
      defer: false
    )

    window.titlebarAppearsTransparent = true
    window.backgroundColor = NSColor(FrameColors.panelBackground)
    window.contentView = hostingView
    window.center()
    window.isReleasedWhenClosed = false
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)

    self.window = window
  }
}
