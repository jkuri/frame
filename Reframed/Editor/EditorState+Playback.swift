import AVFoundation
import CoreMedia

extension EditorState {
  func play() { playerController.play() }
  func pause() { playerController.pause() }

  func togglePlayPause() {
    if isPlaying {
      pause()
    } else {
      if isPreviewMode && hasVideoRegionCuts {
        let t = CMTimeGetSeconds(currentTime)
        let inRegion = videoRegions.contains { t >= $0.startSeconds && t < $0.endSeconds }
        if !inRegion {
          if let next = videoRegions.first(where: { $0.startSeconds > t }) {
            seek(to: CMTime(seconds: next.startSeconds, preferredTimescale: 600))
          } else {
            seek(to: CMTime(seconds: videoRegions[0].startSeconds, preferredTimescale: 600))
          }
        }
      } else if trimEnd.isValid && CMTimeCompare(currentTime, trimEnd) >= 0 {
        seek(to: trimStart)
      }
      play()
    }
  }

  func skipForward(_ seconds: Double = 1.0) {
    let target = CMTimeAdd(currentTime, CMTime(seconds: seconds, preferredTimescale: 600))
    let clamped = CMTimeMinimum(target, trimEnd)
    seek(to: clamped)
  }

  func skipBackward(_ seconds: Double = 1.0) {
    let target = CMTimeSubtract(currentTime, CMTime(seconds: seconds, preferredTimescale: 600))
    let clamped = CMTimeMaximum(target, trimStart)
    seek(to: clamped)
  }

  func seek(to time: CMTime) {
    playerController.seek(to: time)
  }

  func updateTrimStart(_ time: CMTime) {
    trimStart = time
  }

  func updateTrimEnd(_ time: CMTime) {
    trimEnd = time
    playerController.trimEnd = time
  }
}
