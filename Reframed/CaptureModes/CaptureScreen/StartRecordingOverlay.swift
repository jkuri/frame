import AppKit
import SwiftUI

struct StartRecordingOverlayView: View {
  let screens: [NSScreen]
  let delay: Int
  var onCountdownStart: ((NSScreen) -> Void)?
  let onCancel: () -> Void
  let onStart: (NSScreen) -> Void

  @State private var activeScreen: NSScreen?
  @State private var eventMonitor: Any?
  @State private var countdownStarted = false

  private func toLocal(_ rect: CGRect) -> CGRect {
    let unionOrigin = NSScreen.unionFrame.origin
    return CGRect(
      x: rect.origin.x - unionOrigin.x,
      y: rect.origin.y - unionOrigin.y,
      width: rect.width,
      height: rect.height
    )
  }

  private func screenForMouseLocation() -> NSScreen? {
    let mouseLocation = NSEvent.mouseLocation
    return screens.first { $0.frame.contains(mouseLocation) }
  }

  private func resolution(for screen: NSScreen) -> String {
    let width = Int(screen.frame.width * screen.backingScaleFactor)
    let height = Int(screen.frame.height * screen.backingScaleFactor)
    return "\(width) \u{00d7} \(height)"
  }

  var body: some View {
    GeometryReader { _ in
      ZStack {
        ReframedColors.overlayDimBackground
          .edgesIgnoringSafeArea(.all)

        if let screen = activeScreen {
          let localFrame = toLocal(screen.frame)

          VStack(spacing: 12) {
            Text(screen.localizedName)
              .font(.system(size: 14, weight: .medium))
              .foregroundStyle(Color.black)

            Text(resolution(for: screen))
              .font(.system(size: 12))
              .foregroundStyle(Color.black.opacity(0.6))

            StartRecordingButton(
              delay: delay,
              onCountdownStart: {
                countdownStarted = true
                if let screen = activeScreen {
                  onCountdownStart?(screen)
                }
              },
              onCancel: { onCancel() },
              action: {
                if let screen = activeScreen {
                  onStart(screen)
                }
              }
            )
          }
          .padding(24)
          .background(ReframedColors.overlayCardBackground)
          .clipShape(RoundedRectangle(cornerRadius: 16))
          .shadow(radius: 20)
          .position(x: localFrame.midX, y: localFrame.midY)
        }

        Button("") { onCancel() }
          .keyboardShortcut(.escape, modifiers: [])
          .opacity(0)
          .frame(width: 0, height: 0)
      }
    }
    .onAppear {
      activeScreen = screenForMouseLocation() ?? screens.first
      eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { event in
        if !countdownStarted {
          activeScreen = screenForMouseLocation() ?? activeScreen
        }
        return event
      }
    }
    .onDisappear {
      if let monitor = eventMonitor {
        NSEvent.removeMonitor(monitor)
        eventMonitor = nil
      }
    }
  }
}

@MainActor
final class StartRecordingWindow: NSPanel {
  init(
    delay: Int,
    onCountdownStart: @escaping @MainActor (NSScreen) -> Void,
    onCancel: @escaping @MainActor () -> Void,
    onStart: @escaping @MainActor (NSScreen) -> Void
  ) {
    let unionRect = NSScreen.unionFrame

    super.init(
      contentRect: unionRect,
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
    acceptsMouseMovedEvents = true

    let view = StartRecordingOverlayView(
      screens: NSScreen.screens,
      delay: delay,
      onCountdownStart: onCountdownStart,
      onCancel: onCancel,
      onStart: onStart
    )
    let hostingView = NSHostingView(rootView: view)
    hostingView.sizingOptions = [.minSize, .maxSize]
    contentView = hostingView

    setFrame(unionRect, display: true)
  }

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { false }
}
