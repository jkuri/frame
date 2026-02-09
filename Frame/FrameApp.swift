import MenuBarExtraAccess
import SwiftUI

@main
struct FrameApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @State private var isMenuPresented = false
  @State private var session = SessionState()

  init() {
    LogBootstrap.configure()
  }

  var body: some Scene {
    MenuBarExtra {
      MenuBarView(session: session, isMenuPresented: $isMenuPresented)
    } label: {
      MenuBarIconView(state: session.state)
    }
    .menuBarExtraStyle(.window)
    .menuBarExtraAccess(isPresented: $isMenuPresented)
  }
}
