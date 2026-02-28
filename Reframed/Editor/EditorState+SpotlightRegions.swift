import CoreMedia
import Foundation

extension EditorState {
  func isSpotlightActive(at time: Double) -> Bool {
    guard spotlightEnabled else { return false }
    if spotlightRegions.isEmpty { return true }
    return spotlightRegions.contains { time >= $0.startSeconds && time <= $0.endSeconds }
  }

  func addSpotlightRegion(atTime time: Double) {
    let dur = CMTimeGetSeconds(duration)
    let desiredHalf = min(5.0, dur / 2)
    var gapStart: Double = 0
    var gapEnd: Double = dur
    var insertIdx = spotlightRegions.count

    for i in 0..<spotlightRegions.count {
      if time < spotlightRegions[i].startSeconds {
        gapEnd = spotlightRegions[i].startSeconds
        insertIdx = i
        break
      }
      gapStart = spotlightRegions[i].endSeconds
    }
    if insertIdx == spotlightRegions.count {
      gapEnd = dur
    }

    guard gapEnd - gapStart >= 0.05 else { return }

    let regionStart = max(gapStart, time - desiredHalf)
    let regionEnd = min(gapEnd, time + desiredHalf)
    let finalStart = max(gapStart, min(regionStart, regionEnd - 0.05))
    let finalEnd = min(gapEnd, max(regionEnd, finalStart + 0.05))

    spotlightRegions.insert(
      SpotlightRegionData(startSeconds: finalStart, endSeconds: finalEnd),
      at: insertIdx
    )
    spotlightRegions.sort { $0.startSeconds < $1.startSeconds }
  }

  func removeSpotlightRegion(regionId: UUID) {
    spotlightRegions.removeAll { $0.id == regionId }
  }

  func updateSpotlightRegionStart(regionId: UUID, newStart: Double) {
    guard let idx = spotlightRegions.firstIndex(where: { $0.id == regionId }) else { return }
    let minStart: Double = idx > 0 ? spotlightRegions[idx - 1].endSeconds : 0
    let maxStart = spotlightRegions[idx].endSeconds - 0.01
    spotlightRegions[idx].startSeconds = max(minStart, min(maxStart, newStart))
    spotlightRegions.sort { $0.startSeconds < $1.startSeconds }
  }

  func updateSpotlightRegionEnd(regionId: UUID, newEnd: Double) {
    guard let idx = spotlightRegions.firstIndex(where: { $0.id == regionId }) else { return }
    let dur = CMTimeGetSeconds(duration)
    let maxEnd: Double =
      idx < spotlightRegions.count - 1
      ? spotlightRegions[idx + 1].startSeconds : dur
    let minEnd = spotlightRegions[idx].startSeconds + 0.01
    spotlightRegions[idx].endSeconds = max(minEnd, min(maxEnd, newEnd))
    spotlightRegions.sort { $0.startSeconds < $1.startSeconds }
  }

  func updateSpotlightRegionStyle(
    regionId: UUID,
    radius: CGFloat? = nil,
    dimOpacity: CGFloat? = nil,
    edgeSoftness: CGFloat? = nil,
    fadeDuration: Double? = nil
  ) {
    guard let idx = spotlightRegions.firstIndex(where: { $0.id == regionId }) else { return }
    if let radius { spotlightRegions[idx].customRadius = radius }
    if let dimOpacity { spotlightRegions[idx].customDimOpacity = dimOpacity }
    if let edgeSoftness { spotlightRegions[idx].customEdgeSoftness = edgeSoftness }
    if let fadeDuration { spotlightRegions[idx].fadeDuration = fadeDuration }
  }

  func effectiveSpotlightSettings(
    at time: Double
  ) -> (radius: CGFloat, dimOpacity: CGFloat, edgeSoftness: CGFloat) {
    if let region = spotlightRegions.first(where: { time >= $0.startSeconds && time <= $0.endSeconds }) {
      let fade = region.fadeDuration ?? 0
      var factor: CGFloat = 1.0
      if fade > 0 {
        let elapsed = time - region.startSeconds
        let remaining = region.endSeconds - time
        if elapsed < fade {
          factor = min(1.0, CGFloat(elapsed / fade))
        }
        if remaining < fade {
          factor = min(factor, CGFloat(remaining / fade))
        }
      }
      let baseDim = region.customDimOpacity ?? spotlightDimOpacity
      return (
        radius: region.customRadius ?? spotlightRadius,
        dimOpacity: baseDim * factor,
        edgeSoftness: region.customEdgeSoftness ?? spotlightEdgeSoftness
      )
    }
    return (radius: spotlightRadius, dimOpacity: spotlightDimOpacity, edgeSoftness: spotlightEdgeSoftness)
  }

  func moveSpotlightRegion(regionId: UUID, newStart: Double) {
    guard let idx = spotlightRegions.firstIndex(where: { $0.id == regionId }) else { return }
    let dur = CMTimeGetSeconds(duration)
    let regionDuration = spotlightRegions[idx].endSeconds - spotlightRegions[idx].startSeconds
    let minStart: Double = idx > 0 ? spotlightRegions[idx - 1].endSeconds : 0
    let maxStart: Double =
      (idx < spotlightRegions.count - 1
        ? spotlightRegions[idx + 1].startSeconds : dur) - regionDuration
    let clampedStart = max(minStart, min(maxStart, newStart))
    spotlightRegions[idx].startSeconds = clampedStart
    spotlightRegions[idx].endSeconds = clampedStart + regionDuration
    spotlightRegions.sort { $0.startSeconds < $1.startSeconds }
  }
}
