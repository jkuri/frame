import AppKit
import SwiftUI
import ScreenCaptureKit

struct WindowSelectionView: View {
  let session: SessionState
  @StateObject private var windowController = WindowController()
  @State private var showingOptions = false

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Canvas { context, size in
           // 1. Draw Full Dim Background
           let unionRect = CGRect(origin: .zero, size: size)
           context.fill(Path(unionRect), with: .color(.black.opacity(0.55)))


           guard let window = windowController.currentWindow else { return }

           // Offset calculation
           let unionOrigin = NSScreen.unionFrame.origin

           func toLocal(_ rect: CGRect) -> CGRect {
               return CGRect(
                   x: rect.origin.x - unionOrigin.x,
                   y: rect.origin.y - unionOrigin.y,
                   width: rect.width,
                   height: rect.height
               )
           }

           let targetRect = toLocal(window.frame)
           let cornerRadius: CGFloat = 10.0
           let targetPath = Path(roundedRect: targetRect, cornerRadius: cornerRadius)

           // Prepare Occlusion Path
           // Use SCWindows to determine occlusion for the border mask
           var occlusionPath = Path()

           // Resolve SCWindow ID to find index
           // window.id might be 0 if unmatched, so try to match by PID/Frame if needed
           // But WindowController tries to resolve ID.
           let scID = CGWindowID(window.id)

           if scID != 0,
              let matchIndex = windowController.scWindows.firstIndex(where: { $0.windowID == scID }) {
               // Occluders are windows ABOVE this one (lower index in scWindows list?)
               // SCWindow list from shareable content is usually z-ordered (front to back).
               // So 0 is top-most.
               // Verify this assumption: "The windows in the array are ordered from front to back." (Apple Docs)
               // Yes. So if our window is at index N, indices 0...(N-1) are occluders.

               let potentialOccluders = windowController.scWindows[0..<matchIndex]
               for occluder in potentialOccluders {
                   // Only consider relevant occluders (layer 0, reasonable size)
                   // We trust SCK to give us the visual order.
                   if occluder.windowLayer == 0 && occluder.frame.width > 20 {
                        let oRect = toLocal(CGRect(origin: CGPoint(x: occluder.frame.origin.x, y: occluder.frame.origin.y), size: CGSize(width: occluder.frame.width, height: occluder.frame.height)))
                       if oRect.intersects(targetRect) {
                           let oPath = Path(roundedRect: oRect, cornerRadius: cornerRadius)
                           occlusionPath.addPath(oPath)
                       }
                   }
               }
           }

           // 2. Cut Hole (Spotlight)
           context.blendMode = .destinationOut
           context.fill(targetPath, with: .color(.black))
           context.blendMode = .normal

           // 3. Patch Hole (Restore Dimming for Occluded Areas)
           if !occlusionPath.isEmpty {
               context.fill(occlusionPath, with: .color(.black.opacity(0.55)))
           }

           // 4. Draw Highlight Tint (Visible Areas Only)
           context.drawLayer { layer in
               layer.fill(targetPath, with: .color(.white.opacity(0.05)))

               if !occlusionPath.isEmpty {
                   layer.blendMode = .destinationOut
                   layer.fill(occlusionPath, with: .color(.black))
               }
           }

           // 5. Draw Border (Masked)
           context.drawLayer { layer in
               layer.stroke(targetPath, with: .color(Color(nsColor: .controlAccentColor)), lineWidth: 4)

               if !occlusionPath.isEmpty {
                   layer.blendMode = .destinationOut
                   layer.fill(occlusionPath, with: .color(.black))
               }
           }
        }
        .edgesIgnoringSafeArea(.all)
        .onTapGesture {
             if let info = windowController.currentWindow {
                 // Try to find the matching SCWindow to confirm
                 // Matches by ID first, then fallback to PID+Frame
                 if let scWindow = windowController.scWindows.first(where: {
                     ($0.windowID == CGWindowID(info.id)) ||
                     ($0.owningApplication?.processID == info.appPID && abs($0.frame.origin.x - info.frame.origin.x) < 20)
                 }) {
                     session.confirmWindowSelection(scWindow)
                 } else {
                     print("Could not find matching SCWindow for selection.")
                 }
             }
        }

        // Resize Controls
        if let current = windowController.currentWindow {
            VStack {
                HStack(spacing: 12) {
                    Text(current.appName)
                        .font(.caption)
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(6)

                    Button("720p") {
                        windowController.resize(current, to: CGSize(width: 1280, height: 720))
                    }
                    Button("1080p") {
                        windowController.resize(current, to: CGSize(width: 1920, height: 1080))
                    }
                    Button("Center") {
                        windowController.center(current)
                    }
                }
                .controlSize(.small)
                .buttonStyle(.bordered)
                .padding(8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                .padding(.top, 60)

                Spacer()

                // Cancel button
                Button("Cancel") {
                    session.cancelSelection()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 40)
            }
        } else {
             // Show cancel button even if nothing valid under mouse
             VStack {
                Spacer()
                Button("Cancel") {
                    session.cancelSelection()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 40)
            }
        }
      }
    }
    .onAppear {
        Task { await windowController.updateSCWindows() }
        startTrackingMouse()
    }
    .onDisappear {
        stopTrackingMouse()
    }
  }

  private func updateHoveredWindow(at location: CGPoint) {
      if let found = windowController.findWindow(at: location) {
          windowController.currentWindow = found
      } else {
          windowController.currentWindow = nil
      }
  }

  @State private var eventMonitor: Any?

  private func startTrackingMouse() {
    eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { event in
        let mouseLocation = NSEvent.mouseLocation
        // Convert to Top-Left based logic if needed?
        // AX uses global coordinates (Top-Left 0,0).
        // NSEvent.mouseLocation is Bottom-Left 0,0.

        let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? 0
        let flippedY = primaryScreenHeight - mouseLocation.y
        let globalLocation = CGPoint(x: mouseLocation.x, y: flippedY)

        updateHoveredWindow(at: globalLocation)
        return event
    }
  }

  private func stopTrackingMouse() {
    if let monitor = eventMonitor {
        NSEvent.removeMonitor(monitor)
        eventMonitor = nil
    }
  }
}
