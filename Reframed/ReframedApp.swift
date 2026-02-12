import SwiftUI

@main
struct ReframedApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  init() {
    LogBootstrap.configure()
  }

  var body: some Scene {
    Settings {
      EmptyView()
    }
  }
}
