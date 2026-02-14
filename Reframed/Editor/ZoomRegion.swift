import Foundation

struct ZoomRegion {
  let startIndex: Int
  let count: Int
  let startTime: Double
  let zoomStartTime: Double
  let zoomEndTime: Double
  let endTime: Double
  let isAuto: Bool
  let peakZoom: Double
}

func groupZoomRegions(from keyframes: [ZoomKeyframe]) -> [ZoomRegion] {
  guard keyframes.count >= 2 else { return [] }

  var regions: [ZoomRegion] = []
  var i = 0

  while i < keyframes.count {
    if keyframes[i].zoomLevel <= 1.0 && i + 1 < keyframes.count && keyframes[i + 1].zoomLevel > 1.0 {
      let regionStart = i
      var j = i + 1
      var peak = keyframes[j].zoomLevel

      while j < keyframes.count && keyframes[j].zoomLevel > 1.0 {
        peak = max(peak, keyframes[j].zoomLevel)
        j += 1
      }

      let regionEnd: Int
      if j < keyframes.count && keyframes[j].zoomLevel <= 1.0 {
        regionEnd = j
      } else {
        regionEnd = j - 1
      }

      let count = regionEnd - regionStart + 1
      if count >= 2 {
        let zoomStart = keyframes[regionStart + 1].t
        let zoomEnd: Double
        if regionEnd > regionStart + 1 && keyframes[regionEnd].zoomLevel <= 1.0 {
          zoomEnd = keyframes[regionEnd - 1].t
        } else {
          zoomEnd = keyframes[regionEnd].t
        }

        regions.append(
          ZoomRegion(
            startIndex: regionStart,
            count: count,
            startTime: keyframes[regionStart].t,
            zoomStartTime: zoomStart,
            zoomEndTime: zoomEnd,
            endTime: keyframes[regionEnd].t,
            isAuto: keyframes[regionStart].isAuto,
            peakZoom: peak
          )
        )
      }

      i = regionEnd + 1
    } else if keyframes[i].zoomLevel > 1.0 {
      let regionStart = i
      var j = i
      var peak = keyframes[j].zoomLevel

      while j < keyframes.count && keyframes[j].zoomLevel > 1.0 {
        peak = max(peak, keyframes[j].zoomLevel)
        j += 1
      }

      let regionEnd: Int
      if j < keyframes.count && keyframes[j].zoomLevel <= 1.0 {
        regionEnd = j
      } else {
        regionEnd = j - 1
      }

      let count = regionEnd - regionStart + 1
      let zoomEnd: Double
      if regionEnd > regionStart && keyframes[regionEnd].zoomLevel <= 1.0 {
        zoomEnd = keyframes[regionEnd - 1].t
      } else {
        zoomEnd = keyframes[regionEnd].t
      }

      regions.append(
        ZoomRegion(
          startIndex: regionStart,
          count: count,
          startTime: keyframes[regionStart].t,
          zoomStartTime: keyframes[regionStart].t,
          zoomEndTime: zoomEnd,
          endTime: keyframes[regionEnd].t,
          isAuto: keyframes[regionStart].isAuto,
          peakZoom: peak
        )
      )

      i = regionEnd + 1
    } else {
      i += 1
    }
  }

  return regions
}

enum RegionDragType {
  case move, resizeLeft, resizeRight
}
