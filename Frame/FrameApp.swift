import SwiftUI
import MenuBarExtraAccess

@main
struct FrameApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isMenuPresented = false
    @State private var coordinator = CaptureCoordinator()

    init() {
        LogBootstrap.configure()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(coordinator: coordinator, isMenuPresented: $isMenuPresented)
        } label: {
            MenuBarIconView(state: coordinator.ui.state)
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $isMenuPresented)
    }
}
