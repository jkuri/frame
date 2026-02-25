import CoreMedia
import Foundation

extension EditorState {
  func generateAutoZoom() {
    guard let provider = cursorMetadataProvider else { return }
    let config = ZoomDetectorConfig(
      zoomLevel: zoomLevel,
      dwellThresholdSeconds: zoomDwellThreshold,
      transitionDuration: zoomTransitionSpeed
    )
    let dur = CMTimeGetSeconds(duration)
    var newKeyframes = ZoomDetector.detect(from: provider.metadata, duration: dur, config: config)

    if let existing = zoomTimeline {
      let autoRegions = groupZoomRegions(from: newKeyframes)
      let manualKeyframes = existing.allKeyframes.filter { !$0.isAuto }
      let manualRegions = groupZoomRegions(from: manualKeyframes)

      for manualRegion in manualRegions {
        let overlaps = autoRegions.contains { auto in
          manualRegion.startTime < auto.endTime && manualRegion.endTime > auto.startTime
        }
        if !overlaps {
          let regionKfs = Array(manualKeyframes[manualRegion.startIndex..<(manualRegion.startIndex + manualRegion.count)])
          newKeyframes.append(contentsOf: regionKfs)
        }
      }
    }

    zoomTimeline = ZoomTimeline(keyframes: newKeyframes)
  }

  func clearAutoZoom() {
    guard let existing = zoomTimeline else { return }
    let manualKeyframes = existing.allKeyframes.filter { !$0.isAuto }
    if manualKeyframes.isEmpty {
      zoomTimeline = nil
    } else {
      zoomTimeline = ZoomTimeline(keyframes: manualKeyframes)
    }
  }

  func addManualZoomKeyframe(at time: Double, center: CGPoint) {
    let dur = CMTimeGetSeconds(duration)
    let holdDuration = min(10.0, dur / 2)
    let holdEnd = min(dur, time + holdDuration)
    let transIn = max(0, time - zoomTransitionSpeed)
    let transOut = min(dur, holdEnd + zoomTransitionSpeed)

    if let existing = zoomTimeline {
      let existingRegions = groupZoomRegions(from: existing.allKeyframes)
      let overlaps = existingRegions.contains { region in
        transIn < region.endTime && transOut > region.startTime
      }
      if overlaps { return }
    }

    let newKeyframes: [ZoomKeyframe] = [
      ZoomKeyframe(t: transIn, zoomLevel: 1.0, centerX: center.x, centerY: center.y, isAuto: false),
      ZoomKeyframe(t: time, zoomLevel: zoomLevel, centerX: center.x, centerY: center.y, isAuto: false),
      ZoomKeyframe(t: holdEnd, zoomLevel: zoomLevel, centerX: center.x, centerY: center.y, isAuto: false),
      ZoomKeyframe(t: transOut, zoomLevel: 1.0, centerX: center.x, centerY: center.y, isAuto: false),
    ]

    var existing = zoomTimeline?.allKeyframes ?? []
    existing.append(contentsOf: newKeyframes)
    zoomTimeline = ZoomTimeline(keyframes: existing)
  }

  func removeZoomKeyframe(at index: Int) {
    guard let existing = zoomTimeline else { return }
    var kfs = existing.allKeyframes
    guard index >= 0 && index < kfs.count else { return }
    kfs.remove(at: index)
    if kfs.isEmpty {
      zoomTimeline = nil
    } else {
      zoomTimeline = ZoomTimeline(keyframes: kfs)
    }
  }

  func removeZoomRegion(startIndex: Int, count: Int) {
    guard let existing = zoomTimeline else { return }
    var kfs = existing.allKeyframes
    let endIndex = startIndex + count
    guard startIndex >= 0 && endIndex <= kfs.count else { return }
    kfs.removeSubrange(startIndex..<endIndex)
    if kfs.isEmpty {
      zoomTimeline = nil
    } else {
      zoomTimeline = ZoomTimeline(keyframes: kfs)
    }
  }

  func updateZoomRegion(startIndex: Int, count: Int, newKeyframes: [ZoomKeyframe]) {
    guard let existing = zoomTimeline else { return }
    var kfs = existing.allKeyframes
    let endIndex = startIndex + count
    guard startIndex >= 0 && endIndex <= kfs.count else { return }
    kfs.replaceSubrange(startIndex..<endIndex, with: newKeyframes)
    zoomTimeline = ZoomTimeline(keyframes: kfs)
  }
}
