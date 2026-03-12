import SwiftUI

extension ZoomKeyframeEditor {
  func effectiveTimes(
    for region: ZoomRegion
  ) -> (start: Double, zoomStart: Double, zoomEnd: Double, end: Double) {
    guard dragRegionStartIndex == region.startIndex, let dt = dragType else {
      return (region.startTime, region.zoomStartTime, region.zoomEndTime, region.endTime)
    }
    let timeDelta = (dragOffset / width) * duration

    let otherRegions = regions.filter { $0.startIndex != region.startIndex }
    let prevEnd: Double = otherRegions.last(where: { $0.endTime <= region.startTime })?.endTime ?? 0
    let nextStart: Double = otherRegions.first(where: { $0.startTime >= region.endTime })?.startTime ?? duration

    switch dt {
    case .move:
      let regionDur = region.endTime - region.startTime
      let clampedStart = max(prevEnd, min(nextStart - regionDur, region.startTime + timeDelta))
      let shift = clampedStart - region.startTime
      return (
        clampedStart,
        region.zoomStartTime + shift,
        region.zoomEndTime + shift,
        clampedStart + regionDur
      )
    case .resizeLeft:
      let origEaseIn = region.zoomStartTime - region.startTime
      let newStart = max(prevEnd, min(region.endTime - 0.05, region.startTime + timeDelta))
      var newHoldStart = newStart + origEaseIn
      newHoldStart = min(newHoldStart, region.zoomEndTime - 0.01)
      let clampedStart = min(newStart, newHoldStart)
      return (
        clampedStart,
        newHoldStart,
        region.zoomEndTime,
        region.endTime
      )
    case .resizeRight:
      let origEaseOut = region.endTime - region.zoomEndTime
      let newEnd = max(region.startTime + 0.05, min(nextStart, region.endTime + timeDelta))
      var newHoldEnd = newEnd - origEaseOut
      newHoldEnd = max(newHoldEnd, region.zoomStartTime + 0.01)
      let clampedEnd = max(newEnd, newHoldEnd)
      return (
        region.startTime,
        region.zoomStartTime,
        newHoldEnd,
        clampedEnd
      )
    }
  }

  func commitDrag(for region: ZoomRegion) {
    guard let dt = dragType else { return }
    let timeDelta = (dragOffset / width) * duration
    var regionKfs = Array(keyframes[region.startIndex..<(region.startIndex + region.count)])

    var proposedStart: Double
    var proposedEnd: Double

    switch dt {
    case .move:
      for i in 0..<regionKfs.count {
        regionKfs[i].t = max(0, min(duration, regionKfs[i].t + timeDelta))
      }
      proposedStart = max(0, region.startTime + timeDelta)
      proposedEnd = min(duration, region.endTime + timeDelta)
    case .resizeLeft:
      let origEaseIn = region.zoomStartTime - region.startTime
      let newStart = max(0, region.startTime + timeDelta)
      var newHoldStart = newStart + origEaseIn
      newHoldStart = min(newHoldStart, region.zoomEndTime - 0.01)
      let clampedStart = min(newStart, newHoldStart)
      if region.endTime - clampedStart < 0.05 { return }
      let firstZoomIdx = regionKfs.firstIndex(where: { $0.zoomLevel > 1.0 })
      for i in 0..<regionKfs.count {
        if regionKfs[i].zoomLevel <= 1.0 && i == 0 {
          regionKfs[i].t = clampedStart
        } else if i == firstZoomIdx {
          regionKfs[i].t = newHoldStart
        }
      }
      proposedStart = clampedStart
      proposedEnd = region.endTime
    case .resizeRight:
      let origEaseOut = region.endTime - region.zoomEndTime
      let newEnd = min(duration, region.endTime + timeDelta)
      var newHoldEnd = newEnd - origEaseOut
      newHoldEnd = max(newHoldEnd, region.zoomStartTime + 0.01)
      let clampedEnd = max(newEnd, newHoldEnd)
      if clampedEnd - region.startTime < 0.05 { return }
      let lastZoomIdx = regionKfs.lastIndex(where: { $0.zoomLevel > 1.0 })
      for i in 0..<regionKfs.count {
        if regionKfs[i].zoomLevel <= 1.0 && i == regionKfs.count - 1 {
          regionKfs[i].t = clampedEnd
        } else if i == lastZoomIdx {
          regionKfs[i].t = newHoldEnd
        }
      }
      proposedStart = region.startTime
      proposedEnd = clampedEnd
    }

    let otherRegions = regions.filter { $0.startIndex != region.startIndex }
    let overlaps = otherRegions.contains { other in
      proposedStart < other.endTime && proposedEnd > other.startTime
    }
    if overlaps { return }

    onUpdateRegion(region.startIndex, region.count, regionKfs)
  }
}
