import Sparkle

@MainActor
final class SparkleUpdater {
  static let shared = SparkleUpdater()

  private let controller: SPUStandardUpdaterController

  private init() {
    controller = SPUStandardUpdaterController(
      startingUpdater: true,
      updaterDelegate: nil,
      userDriverDelegate: nil
    )
    controller.updater.automaticallyChecksForUpdates = true
    controller.updater.updateCheckInterval = 3600
  }

  func checkForUpdates() {
    controller.checkForUpdates(nil)
  }
}
