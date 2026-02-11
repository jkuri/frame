import AVFoundation
import AppKit

@MainActor
final class WebcamPreviewWindow {
  private var panel: NSPanel?
  private var previewLayer: AVCaptureVideoPreviewLayer?
  private var loadingView: NSView?

  private let padding: CGFloat = 6
  private let videoWidth: CGFloat = 180
  private let videoHeight: CGFloat = 135
  private let cornerRadius: CGFloat = 14

  private var totalWidth: CGFloat { videoWidth + padding * 2 }
  private var totalHeight: CGFloat { videoHeight + padding * 2 }

  func showLoading() {
    if panel == nil {
      createPanel()
    }

    previewLayer?.removeFromSuperlayer()
    previewLayer = nil
    loadingView?.removeFromSuperview()

    guard let contentView = panel?.contentView else { return }

    let container = NSView(frame: NSRect(x: padding, y: padding, width: videoWidth, height: videoHeight))
    container.wantsLayer = true
    container.layer?.cornerRadius = cornerRadius - 3
    container.layer?.masksToBounds = true
    container.layer?.backgroundColor = NSColor(white: 0.1, alpha: 1).cgColor

    let spinner = NSProgressIndicator(frame: NSRect(x: (videoWidth - 24) / 2, y: (videoHeight - 24) / 2 + 10, width: 24, height: 24))
    spinner.style = .spinning
    spinner.controlSize = .small
    spinner.startAnimation(nil)
    container.addSubview(spinner)

    let label = NSTextField(labelWithString: "Camera is starting...")
    label.font = NSFont.systemFont(ofSize: 11, weight: .medium)
    label.textColor = NSColor.white.withAlphaComponent(0.6)
    label.alignment = .center
    label.frame = NSRect(x: 0, y: (videoHeight - 24) / 2 - 18, width: videoWidth, height: 16)
    container.addSubview(label)

    contentView.addSubview(container)
    loadingView = container

    panel?.orderFrontRegardless()
  }

  func show(captureSession: AVCaptureSession) {
    if panel == nil {
      createPanel()
    }

    loadingView?.removeFromSuperview()
    loadingView = nil
    previewLayer?.removeFromSuperlayer()
    previewLayer = nil

    guard let contentView = panel?.contentView else { return }

    let videoView = NSView(frame: NSRect(x: padding, y: padding, width: videoWidth, height: videoHeight))
    videoView.wantsLayer = true
    videoView.layer?.cornerRadius = cornerRadius - 3
    videoView.layer?.masksToBounds = true

    let layer = AVCaptureVideoPreviewLayer(session: captureSession)
    layer.videoGravity = .resizeAspectFill
    layer.frame = videoView.bounds
    layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
    videoView.layer?.addSublayer(layer)
    self.previewLayer = layer

    contentView.addSubview(videoView)
    panel?.orderFrontRegardless()
  }

  func showError(_ message: String) {
    if panel == nil {
      createPanel()
    }

    previewLayer?.removeFromSuperlayer()
    previewLayer = nil
    loadingView?.removeFromSuperview()
    loadingView = nil

    guard let contentView = panel?.contentView else { return }

    let container = NSView(frame: NSRect(x: padding, y: padding, width: videoWidth, height: videoHeight))
    container.wantsLayer = true
    container.layer?.cornerRadius = cornerRadius - 3
    container.layer?.masksToBounds = true
    container.layer?.backgroundColor = NSColor(white: 0.1, alpha: 1).cgColor

    let icon = NSImageView(frame: NSRect(x: (videoWidth - 24) / 2, y: (videoHeight - 24) / 2 + 10, width: 24, height: 24))
    icon.image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "Error")
    icon.contentTintColor = .systemOrange
    container.addSubview(icon)

    let label = NSTextField(labelWithString: message)
    label.font = NSFont.systemFont(ofSize: 11, weight: .medium)
    label.textColor = NSColor.white.withAlphaComponent(0.6)
    label.alignment = .center
    label.lineBreakMode = .byTruncatingTail
    label.frame = NSRect(x: 4, y: (videoHeight - 24) / 2 - 18, width: videoWidth - 8, height: 16)
    container.addSubview(label)

    contentView.addSubview(container)
    loadingView = container

    panel?.orderFrontRegardless()
  }

  func close() {
    previewLayer?.removeFromSuperlayer()
    previewLayer = nil
    loadingView?.removeFromSuperview()
    loadingView = nil
    panel?.orderOut(nil)
    panel?.contentView = nil
    panel = nil
  }

  private func createPanel() {
    guard let screen = NSScreen.main else { return }
    let screenFrame = screen.visibleFrame
    let origin = CGPoint(
      x: screenFrame.maxX - totalWidth - 20,
      y: screenFrame.minY + 20
    )

    let panel = NSPanel(
      contentRect: NSRect(origin: origin, size: NSSize(width: totalWidth, height: totalHeight)),
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    panel.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
    panel.isFloatingPanel = true
    panel.isMovableByWindowBackground = true
    panel.hasShadow = true
    panel.backgroundColor = .clear
    panel.isOpaque = false
    panel.sharingType = .none

    let contentView = NSView(frame: NSRect(origin: .zero, size: NSSize(width: totalWidth, height: totalHeight)))
    contentView.wantsLayer = true
    contentView.layer?.cornerRadius = cornerRadius
    contentView.layer?.masksToBounds = true
    contentView.layer?.backgroundColor = NSColor(white: 0.15, alpha: 1).cgColor
    contentView.layer?.borderWidth = 1
    contentView.layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor

    panel.contentView = contentView
    self.panel = panel
  }
}
