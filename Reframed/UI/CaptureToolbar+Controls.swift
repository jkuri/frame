import SwiftUI

extension CaptureToolbar {
  func recordingControls(startedAt: Date, isPaused: Bool) -> some View {
    HStack(spacing: 0) {
      Circle()
        .fill(isPaused ? Color.orange : Color.red)
        .frame(width: 10, height: 10)
        .padding(.leading, 4)

      CompactTimerView(startedAt: startedAt, frozen: isPaused)
        .padding(.horizontal, 10)

      if session.options.captureSystemAudio || session.isMicrophoneOn || session.isCameraOn {
        HStack(spacing: 12) {
          if session.options.captureSystemAudio {
            AudioLevelIcon(icon: "speaker.wave.2.fill", level: session.systemAudioLevel)
          }
          if session.isMicrophoneOn {
            AudioLevelIcon(icon: "mic.fill", level: session.micAudioLevel)
          }
          if session.isCameraOn {
            VStack(spacing: 2) {
              Image(systemName: "web.camera.fill")
                .font(.system(size: FontSize.xs))
                .foregroundStyle(ReframedColors.tertiaryText)
                .frame(height: 20)
              Color.clear.frame(height: 3)
            }
          }
        }
        .padding(.trailing, 2)
      }

      ToolbarDivider()

      if isPaused {
        ToolbarActionButton(icon: "play.fill", tooltip: "Resume") {
          session.resumeRecording()
        }
      } else {
        ToolbarActionButton(icon: "pause.fill", tooltip: "Pause") {
          session.pauseRecording()
        }
      }

      ToolbarActionButton(icon: "stop.fill", tooltip: "Stop") {
        Task {
          try? await session.stopRecording()
        }
      }

      ToolbarDivider()

      ToolbarActionButton(icon: "arrow.counterclockwise", tooltip: "Restart") {
        showRestartAlert = true
      }
    }
    .frame(height: Layout.toolbarHeight)
  }

  var processingContent: some View {
    HStack(spacing: 8) {
      ProgressView()
        .controlSize(.small)
        .scaleEffect(0.8)
        .tint(ReframedColors.primaryText)
      Text("Processing...")
        .font(.system(size: FontSize.xs, weight: .medium))
        .foregroundStyle(ReframedColors.primaryText)
    }
    .frame(minWidth: 150, alignment: .center)
    .frame(height: Layout.toolbarHeight)
    .padding(.horizontal, 8)
  }
}
