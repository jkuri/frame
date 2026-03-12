import AVFoundation
import SwiftUI

extension TimelineView {
  func zoomTrackContent(width: CGFloat, keyframes: [ZoomKeyframe]) -> some View {
    ZoomKeyframeEditor(
      keyframes: keyframes,
      duration: totalSeconds,
      width: width,
      height: trackHeight,
      scrollOffset: scrollOffset,
      timelineZoom: timelineZoom,
      onAddKeyframe: { time in
        if let provider = editorState.cursorMetadataProvider {
          let pos = provider.sample(at: time)
          editorState.addManualZoomKeyframe(at: time, center: pos)
        }
      },
      onRemoveRegion: { startIndex, count in
        editorState.removeZoomRegion(startIndex: startIndex, count: count)
      },
      onUpdateRegion: { startIndex, count, newKeyframes in
        editorState.updateZoomRegion(startIndex: startIndex, count: count, newKeyframes: newKeyframes)
      }
    )
    .frame(width: width, height: trackHeight)
  }

  func trimBorderOverlay(
    width: CGFloat,
    height: CGFloat,
    trimStart: Double,
    trimEnd: Double
  ) -> some View {
    let startX = width * trimStart
    let endX = width * trimEnd
    let selectionWidth = endX - startX

    return ZStack(alignment: .leading) {
      Color.clear.frame(width: width, height: height)

      RoundedRectangle(cornerRadius: Track.borderRadius)
        .stroke(Track.borderColor, lineWidth: Track.borderWidth)
        .frame(width: max(0, selectionWidth), height: height)
        .offset(x: startX)
    }
    .allowsHitTesting(false)
  }

  func trimHandleOverlay(
    width: CGFloat,
    height: CGFloat,
    trimStart: Double,
    trimEnd: Double,
    onTrimStart: @escaping (Double) -> Void,
    onTrimEnd: @escaping (Double) -> Void
  ) -> some View {
    ZStack(alignment: .leading) {
      TrimHandle(
        edge: .leading,
        position: trimStart,
        totalWidth: width,
        height: height
      ) { newFraction in
        let clamped = min(newFraction, trimEnd - 0.01)
        onTrimStart(clamped)
      }

      TrimHandle(
        edge: .trailing,
        position: trimEnd,
        totalWidth: width,
        height: height
      ) { newFraction in
        let clamped = max(newFraction, trimStart + 0.01)
        onTrimEnd(clamped)
      }
    }
  }

  func playheadOverlay(contentWidth: CGFloat, inset: CGFloat) -> some View {
    let frameWidth = contentWidth + inset * 2
    let playheadFraction = CMTimeGetSeconds(editorState.currentTime) / totalSeconds

    return SwiftUI.TimelineView(.animation(paused: !editorState.isPlaying)) { _ in
      let fraction: Double =
        if editorState.isPlaying {
          max(0, min(1, CMTimeGetSeconds(editorState.playerController.screenPlayer.currentTime()) / totalSeconds))
        } else {
          playheadFraction
        }
      let centerX = inset + contentWidth * fraction
      // TimelineHeight should be accessible from TimelineView instance. We calculate it inline here since it depends on Ruler Height
      // Actually we have it in self.timelineHeight, and self.rulerHeight is 32.
      let lineHeight = timelineHeight - 32

      ZStack {
        Rectangle()
          .fill(ReframedColors.primaryText.opacity(0.9))
          .frame(width: 2, height: lineHeight)
          .position(x: centerX, y: 32 + lineHeight / 2)
          .allowsHitTesting(false)

        RoundedRectangle(cornerRadius: Radius.md)
          .fill(ReframedColors.primaryText.opacity(0.9))
          .frame(width: 12, height: 32)
          .position(x: centerX, y: 16)
          .gesture(
            DragGesture(minimumDistance: 0)
              .onChanged { value in
                let fraction = max(0, min(1, (value.location.x - inset) / contentWidth))
                let time = CMTime(seconds: fraction * totalSeconds, preferredTimescale: 600)
                onScrub(time)
              }
          )
      }
      .frame(width: frameWidth, height: timelineHeight)
    }
  }
}
