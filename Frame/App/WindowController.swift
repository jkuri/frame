import AppKit
import ApplicationServices
import ScreenCaptureKit
import Combine

struct WindowInfo: Identifiable, Equatable {
    let id: Int // CGWindowID
    let frame: CGRect
    let title: String
    let appPID: pid_t
    let appName: String
    let axElement: AXUIElement // The AX object for control

    // Equatable for SwiftUI state
    static func == (lhs: WindowInfo, rhs: WindowInfo) -> Bool {
        return lhs.id == rhs.id && lhs.frame == rhs.frame
    }
}

@MainActor
final class WindowController: ObservableObject {
    @Published var currentWindow: WindowInfo?

    // Cache SCWindows to map AX to SCK IDs (for recording)
    private(set) var scWindows: [SCWindow] = []

    init() {
        // Start fetching SCWindows continuously or on-demand?
        // For now, let's fetch on demand or setup a timer if needed.
        // We will call updateSCWindows() from onAppear
    }

    func updateSCWindows() async {
        do {
            let content = try await Permissions.fetchShareableContent()
            // Keep all windows for matching
            self.scWindows = content.windows
        } catch {
            print("Failed to fetch SCWindows: \(error)")
        }
    }

    func findWindow(at point: CGPoint) -> WindowInfo? {
        let axSystem = AXUIElementCreateSystemWide()
        var element: AXUIElement?

        let result = AXUIElementCopyElementAtPosition(axSystem, Float(point.x), Float(point.y), &element)

        if result != .success {
             print("DEBUG: Hit test failed at \(point): \(result.rawValue)")
             return nil
        }

        guard let targetElement = element else { return nil }

        // 2. Walk up to the Window level
        var windowElement = targetElement
        var role: CFTypeRef?
        AXUIElementCopyAttributeValue(windowElement, kAXRoleAttribute as CFString, &role)

        var iterations = 0
        while role as? String != kAXWindowRole {
            if iterations > 10 { break }
            iterations += 1

            var parent: CFTypeRef?
            let err = AXUIElementCopyAttributeValue(windowElement, kAXParentAttribute as CFString, &parent)
            if err == .success, let p = parent {
                windowElement = (p as! AXUIElement)
                AXUIElementCopyAttributeValue(windowElement, kAXRoleAttribute as CFString, &role)
            } else {
                break
            }
        }

        // 3. Extract Window Attributes
        var pid: pid_t = 0
        AXUIElementGetPid(windowElement, &pid)

        // Frame
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &positionRef)
        AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &sizeRef)

        var pos = CGPoint.zero
        var size = CGSize.zero

        if let posRef = positionRef, CFGetTypeID(posRef) == AXValueGetTypeID() {
            AXValueGetValue(posRef as! AXValue, .cgPoint, &pos)
        }
        if let sRef = sizeRef, CFGetTypeID(sRef) == AXValueGetTypeID() {
            AXValueGetValue(sRef as! AXValue, .cgSize, &size)
        }

        let frame = CGRect(origin: pos, size: size)

        // Title
        var titleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(windowElement, kAXTitleAttribute as CFString, &titleRef)
        let title = titleRef as? String ?? ""

        // App Name
        let app = NSRunningApplication(processIdentifier: pid)
        let appName = app?.localizedName ?? "Unknown"

        // 4. Match with SCWindow to get ID
        if let match = scWindows.first(where: {
            $0.owningApplication?.processID == pid &&
            // Allow small pixel tolerance
            abs($0.frame.origin.x - frame.origin.x) < 20 &&
            abs($0.frame.origin.y - frame.origin.y) < 20
        }) {
            return WindowInfo(id: Int(match.windowID), frame: frame, title: title, appPID: pid, appName: appName, axElement: windowElement)
        }

        return WindowInfo(id: 0, frame: frame, title: title, appPID: pid, appName: appName, axElement: windowElement)
    }

    // Control Methods
    func resize(_ window: WindowInfo, to newSize: CGSize) {
        var size = newSize
        // Swift handles &size -> UnsafeRawPointer automatically for C interop
        guard let sizeVal = AXValueCreate(.cgSize, &size) else { return }
        AXUIElementSetAttributeValue(window.axElement, kAXSizeAttribute as CFString, sizeVal)
    }

    func center(_ window: WindowInfo) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        // Screen frame is bottom-left based in Cocoa.
        // AX coordinates: top-left based (0,0 is top-left of primary screen).

        // Logic:
        // 1. Calculate center in Cocoa coordinates
        // 2. Flip Y to get global (AX) coordinates

        let newX = screenFrame.midX - window.frame.width / 2
        let cocoaY = screenFrame.midY - window.frame.height / 2 // Bottom of top-left? No, bottom-up.

        // Cocoa top-left relative Y:
        // screen.frame.height - (cocoaY + height) -> Top Y?
        // Let's use simpler logic:
        // Center X is same.
        // Center Y (from top) = ScreenHeight/2 - WindowHeight/2

        let targetX = screenFrame.width / 2 - window.frame.width / 2
        let targetY = screenFrame.height / 2 - window.frame.height / 2 // From top

        var point = CGPoint(x: screenFrame.origin.x + targetX, y: screenFrame.origin.y + targetY)
        // Adjust for multi-monitor if needed, but assuming main screen for now.

        guard let pointVal = AXValueCreate(.cgPoint, &point) else { return }
        AXUIElementSetAttributeValue(window.axElement, kAXPositionAttribute as CFString, pointVal)
    }
}
