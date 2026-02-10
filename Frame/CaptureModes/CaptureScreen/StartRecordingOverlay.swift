import AppKit
import SwiftUI

struct StartRecordingOverlayView: View {
  let displayName: String
  let resolution: String
  let onStart: () -> Void

  var body: some View {
    VStack(spacing: 12) {
      Text(displayName)
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.white)

      Text(resolution)
        .font(.system(size: 12))
        .foregroundStyle(.white.opacity(0.6))

      Button(action: onStart) {
        HStack(spacing: 6) {
          Image(systemName: "record.circle")
            .font(.system(size: 15, weight: .semibold))
          Text("Start recording")
            .font(.system(size: 15, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
        .frame(height: 48)
        .background(Color(nsColor: .controlAccentColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
      }
      .buttonStyle(.plain)
    }
    .padding(24)
    .background(.black.opacity(0.8))
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .shadow(radius: 20)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.black.opacity(0.4))
  }
}

@MainActor
final class StartRecordingWindow: NSPanel {
  init(screen: NSScreen, onStart: @escaping @MainActor () -> Void) {
    super.init(
      contentRect: screen.frame,
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    isOpaque = false
    backgroundColor = .clear
    level = .screenSaver
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    hasShadow = true
    hidesOnDeactivate = false
    ignoresMouseEvents = false

    let displayName = screen.localizedName
    let width = Int(screen.frame.width * screen.backingScaleFactor)
    let height = Int(screen.frame.height * screen.backingScaleFactor)
    let resolution = "\(width) × \(height)"

    let view = StartRecordingOverlayView(
      displayName: displayName,
      resolution: resolution,
      onStart: onStart
    )
    let hostingView = NSHostingView(rootView: view)
    hostingView.sizingOptions = [.minSize, .maxSize]
    contentView = hostingView

    setFrame(screen.frame, display: true)
  }

  override var canBecomeKey: Bool { false }
  override var canBecomeMain: Bool { false }
}
