import SwiftUI

struct CaptureToolbar: View {
  let session: SessionState
  @State var showOptions = false
  @State var showSettings = false
  @State var showRestartAlert = false
  @State var showDevicePopover = false
  @State var showCameraPicker = false
  @State var showMicPicker = false

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    let _ = colorScheme
    HStack(spacing: 0) {
      switch session.state {
      case .recording(let startedAt):
        recordingControls(startedAt: startedAt, isPaused: false)
      case .paused(let elapsed):
        let pseudoStart = Date().addingTimeInterval(-elapsed)
        recordingControls(startedAt: pseudoStart, isPaused: true)
      case .processing:
        processingContent
      default:
        modeSelectionContent
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(ReframedColors.background)
    .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
    .overlay(
      RoundedRectangle(cornerRadius: Radius.xl)
        .strokeBorder(ReframedColors.border, lineWidth: 0.5)
    )
    .alert("Restart Recording?", isPresented: $showRestartAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Restart", role: .destructive) {
        session.restartRecording()
      }
    } message: {
      Text("This will discard the current recording and return to mode selection.")
    }
  }
}
