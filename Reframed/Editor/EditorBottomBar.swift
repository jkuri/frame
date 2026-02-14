import AVFoundation
import SwiftUI

struct EditorBottomBar: View {
  @Bindable var editorState: EditorState
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    let _ = colorScheme
    HStack(spacing: 12) {
      Button(action: {
        editorState.togglePlayPause()
      }) {
        Image(systemName: editorState.isPlaying ? "pause.fill" : "play.fill")
          .font(.system(size: 14))
          .frame(width: 28, height: 28)
      }
      .buttonStyle(.plain)
      .foregroundStyle(ReframedColors.primaryText)

      timeDisplay

      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
  }

  private var timeDisplay: some View {
    let current = formatDuration(editorState.currentTime)
    let total = formatDuration(editorState.duration)
    return Text("\(current) / \(total)")
      .font(.system(size: 12, design: .monospaced))
      .foregroundStyle(ReframedColors.secondaryText)
  }
}
