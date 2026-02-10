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
      contentRect: NSRect(x: 0, y: 0, width: 480, height: 360),
      styleMask: [.titled, .closable, .miniaturizable],
      backing: .buffered,
      defer: false
    )
    window.title = "Frame Settings"
    window.contentView = hostingView
    window.center()
    window.isReleasedWhenClosed = false
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)

    self.window = window
  }
}
