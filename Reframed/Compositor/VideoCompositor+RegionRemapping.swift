import AVFoundation
import CoreMedia
import Foundation

extension VideoCompositor {
  struct VideoSegment {
    let sourceRange: CMTimeRange
    let compositionStart: CMTime
  }

  struct RemappedRegions {
    let cameraFullscreen: [RegionTransitionInfo]
    let cameraHidden: [RegionTransitionInfo]
    let cameraCustom: [CameraCustomRegion]
    let video: [RegionTransitionInfo]
    let captions: [CaptionSegment]
    let spotlight: [SpotlightRegionData]
  }

  static func remapAllRegions(
    config: ExportConfiguration,
    hasVideoRegions: Bool,
    videoSegments: [VideoSegment],
    effectiveTrim: CMTimeRange,
    scaleX: CGFloat
  ) -> RemappedRegions {
    RemappedRegions(
      cameraFullscreen: (config.cameraFullscreenRegions ?? []).flatMap {
        remapRegion($0, hasVideoRegions: hasVideoRegions, videoSegments: videoSegments, effectiveTrim: effectiveTrim)
      },
      cameraHidden: (config.cameraHiddenRegions ?? []).flatMap {
        remapRegion($0, hasVideoRegions: hasVideoRegions, videoSegments: videoSegments, effectiveTrim: effectiveTrim)
      },
      cameraCustom: (config.cameraCustomRegions ?? []).flatMap {
        remapCustomRegion(
          $0,
          hasVideoRegions: hasVideoRegions,
          videoSegments: videoSegments,
          effectiveTrim: effectiveTrim,
          scaleX: scaleX
        )
      },
      video: remapVideoRegions(
        videoRegions: hasVideoRegions ? config.videoRegions : nil,
        videoSegments: videoSegments
      ),
      captions: remapCaptionSegments(
        captionSegments: config.captionSegments,
        captionsEnabled: config.captionsEnabled,
        hasVideoRegions: hasVideoRegions,
        videoSegments: videoSegments,
        effectiveTrim: effectiveTrim
      ),
      spotlight: config.spotlightRegions.flatMap {
        remapSpotlightRegion(
          $0,
          hasVideoRegions: hasVideoRegions,
          videoSegments: videoSegments,
          effectiveTrim: effectiveTrim
        )
      }
    )
  }

  private static func remapRegion(
    _ region: RegionTransitionInfo,
    hasVideoRegions: Bool,
    videoSegments: [VideoSegment],
    effectiveTrim: CMTimeRange
  ) -> [RegionTransitionInfo] {
    if hasVideoRegions {
      var results: [RegionTransitionInfo] = []
      for seg in videoSegments {
        let overlapStart = max(
          CMTimeGetSeconds(region.timeRange.start),
          CMTimeGetSeconds(seg.sourceRange.start)
        )
        let overlapEnd = min(
          CMTimeGetSeconds(region.timeRange.end),
          CMTimeGetSeconds(seg.sourceRange.end)
        )
        guard overlapEnd > overlapStart else { continue }
        let segStart = CMTimeGetSeconds(seg.sourceRange.start)
        let compStart = CMTimeGetSeconds(seg.compositionStart)
        let mappedStart = compStart + (overlapStart - segStart)
        let mappedEnd = compStart + (overlapEnd - segStart)
        results.append(
          RegionTransitionInfo(
            timeRange: CMTimeRange(
              start: CMTime(seconds: mappedStart, preferredTimescale: 600),
              end: CMTime(seconds: mappedEnd, preferredTimescale: 600)
            ),
            entryTransition: region.entryTransition,
            entryDuration: region.entryDuration,
            exitTransition: region.exitTransition,
            exitDuration: region.exitDuration
          )
        )
      }
      return results
    }
    let overlapStart = CMTimeMaximum(region.timeRange.start, effectiveTrim.start)
    let overlapEnd = CMTimeMinimum(region.timeRange.end, effectiveTrim.end)
    guard CMTimeCompare(overlapEnd, overlapStart) > 0 else { return [] }
    return [
      RegionTransitionInfo(
        timeRange: CMTimeRange(
          start: CMTimeSubtract(overlapStart, effectiveTrim.start),
          end: CMTimeSubtract(overlapEnd, effectiveTrim.start)
        ),
        entryTransition: region.entryTransition,
        entryDuration: region.entryDuration,
        exitTransition: region.exitTransition,
        exitDuration: region.exitDuration
      )
    ]
  }

  private static func remapCustomRegion(
    _ region: CameraCustomRegion,
    hasVideoRegions: Bool,
    videoSegments: [VideoSegment],
    effectiveTrim: CMTimeRange,
    scaleX: CGFloat
  ) -> [CameraCustomRegion] {
    if hasVideoRegions {
      var results: [CameraCustomRegion] = []
      for seg in videoSegments {
        let overlapStart = max(
          CMTimeGetSeconds(region.timeRange.start),
          CMTimeGetSeconds(seg.sourceRange.start)
        )
        let overlapEnd = min(
          CMTimeGetSeconds(region.timeRange.end),
          CMTimeGetSeconds(seg.sourceRange.end)
        )
        guard overlapEnd > overlapStart else { continue }
        let segStart = CMTimeGetSeconds(seg.sourceRange.start)
        let compStart = CMTimeGetSeconds(seg.compositionStart)
        let mappedStart = compStart + (overlapStart - segStart)
        let mappedEnd = compStart + (overlapEnd - segStart)
        results.append(
          CameraCustomRegion(
            timeRange: CMTimeRange(
              start: CMTime(seconds: mappedStart, preferredTimescale: 600),
              end: CMTime(seconds: mappedEnd, preferredTimescale: 600)
            ),
            layout: region.layout,
            cameraAspect: region.cameraAspect,
            cornerRadius: region.cornerRadius,
            shadow: region.shadow,
            borderWidth: region.borderWidth * scaleX,
            borderColor: region.borderColor,
            mirrored: region.mirrored,
            entryTransition: region.entryTransition,
            entryDuration: region.entryDuration,
            exitTransition: region.exitTransition,
            exitDuration: region.exitDuration
          )
        )
      }
      return results
    }
    let overlapStart = CMTimeMaximum(region.timeRange.start, effectiveTrim.start)
    let overlapEnd = CMTimeMinimum(region.timeRange.end, effectiveTrim.end)
    guard CMTimeCompare(overlapEnd, overlapStart) > 0 else { return [] }
    return [
      CameraCustomRegion(
        timeRange: CMTimeRange(
          start: CMTimeSubtract(overlapStart, effectiveTrim.start),
          end: CMTimeSubtract(overlapEnd, effectiveTrim.start)
        ),
        layout: region.layout,
        cameraAspect: region.cameraAspect,
        cornerRadius: region.cornerRadius,
        shadow: region.shadow,
        borderWidth: region.borderWidth,
        borderColor: region.borderColor,
        mirrored: region.mirrored,
        entryTransition: region.entryTransition,
        entryDuration: region.entryDuration,
        exitTransition: region.exitTransition,
        exitDuration: region.exitDuration
      )
    ]
  }

  private static func remapSpotlightRegion(
    _ region: SpotlightRegionData,
    hasVideoRegions: Bool,
    videoSegments: [VideoSegment],
    effectiveTrim: CMTimeRange
  ) -> [SpotlightRegionData] {
    if hasVideoRegions {
      var results: [SpotlightRegionData] = []
      for seg in videoSegments {
        let overlapStart = max(region.startSeconds, CMTimeGetSeconds(seg.sourceRange.start))
        let overlapEnd = min(region.endSeconds, CMTimeGetSeconds(seg.sourceRange.end))
        guard overlapEnd > overlapStart else { continue }
        let segStart = CMTimeGetSeconds(seg.sourceRange.start)
        let compStart = CMTimeGetSeconds(seg.compositionStart)
        let mappedStart = compStart + (overlapStart - segStart)
        let mappedEnd = compStart + (overlapEnd - segStart)
        var mapped = region
        mapped.id = UUID()
        mapped.startSeconds = mappedStart
        mapped.endSeconds = mappedEnd
        results.append(mapped)
      }
      return results
    }
    let trimStart = CMTimeGetSeconds(effectiveTrim.start)
    let trimEnd = CMTimeGetSeconds(effectiveTrim.end)
    let overlapStart = max(region.startSeconds, trimStart)
    let overlapEnd = min(region.endSeconds, trimEnd)
    guard overlapEnd > overlapStart else { return [] }
    var mapped = region
    mapped.startSeconds = overlapStart - trimStart
    mapped.endSeconds = overlapEnd - trimStart
    return [mapped]
  }

  private static func remapVideoRegions(
    videoRegions: [RegionTransitionInfo]?,
    videoSegments: [VideoSegment]
  ) -> [RegionTransitionInfo] {
    guard let videoRegions = videoRegions, !videoRegions.isEmpty else { return [] }
    var result: [RegionTransitionInfo] = []
    for seg in videoSegments {
      let compStart = CMTimeGetSeconds(seg.compositionStart)
      let segDuration = CMTimeGetSeconds(seg.sourceRange.duration)
      for vr in videoRegions {
        let vrStart = CMTimeGetSeconds(vr.timeRange.start)
        let vrEnd = CMTimeGetSeconds(vr.timeRange.end)
        let segSourceStart = CMTimeGetSeconds(seg.sourceRange.start)
        let segSourceEnd = CMTimeGetSeconds(seg.sourceRange.end)
        guard abs(vrStart - segSourceStart) < 0.01 && abs(vrEnd - segSourceEnd) < 0.01 else { continue }
        result.append(
          RegionTransitionInfo(
            timeRange: CMTimeRange(
              start: CMTime(seconds: compStart, preferredTimescale: 600),
              end: CMTime(seconds: compStart + segDuration, preferredTimescale: 600)
            ),
            entryTransition: vr.entryTransition,
            entryDuration: vr.entryDuration,
            exitTransition: vr.exitTransition,
            exitDuration: vr.exitDuration
          )
        )
      }
    }
    return result
  }

  private static func remapCaptionSegments(
    captionSegments: [CaptionSegment],
    captionsEnabled: Bool,
    hasVideoRegions: Bool,
    videoSegments: [VideoSegment],
    effectiveTrim: CMTimeRange
  ) -> [CaptionSegment] {
    guard captionsEnabled, !captionSegments.isEmpty else { return [] }
    if hasVideoRegions {
      var results: [CaptionSegment] = []
      for seg in captionSegments {
        for vs in videoSegments {
          let overlapStart = max(seg.startSeconds, CMTimeGetSeconds(vs.sourceRange.start))
          let overlapEnd = min(seg.endSeconds, CMTimeGetSeconds(vs.sourceRange.end))
          guard overlapEnd > overlapStart else { continue }
          let segStart = CMTimeGetSeconds(vs.sourceRange.start)
          let compStart = CMTimeGetSeconds(vs.compositionStart)
          let mappedStart = compStart + (overlapStart - segStart)
          let mappedEnd = compStart + (overlapEnd - segStart)
          let remappedWords = seg.words?.compactMap { w -> CaptionWord? in
            let wStart = max(w.startSeconds, overlapStart)
            let wEnd = min(w.endSeconds, overlapEnd)
            guard wEnd > wStart else { return nil }
            return CaptionWord(
              word: w.word,
              startSeconds: compStart + (wStart - segStart),
              endSeconds: compStart + (wEnd - segStart)
            )
          }
          results.append(
            CaptionSegment(
              startSeconds: mappedStart,
              endSeconds: mappedEnd,
              text: seg.text,
              words: remappedWords
            )
          )
        }
      }
      return results
    }
    let trimStart = CMTimeGetSeconds(effectiveTrim.start)
    return captionSegments.compactMap { seg in
      let overlapStart = max(seg.startSeconds, trimStart)
      let overlapEnd = min(seg.endSeconds, CMTimeGetSeconds(effectiveTrim.end))
      guard overlapEnd > overlapStart else { return nil }
      let remappedWords = seg.words?.compactMap { w -> CaptionWord? in
        let wStart = max(w.startSeconds, trimStart)
        let wEnd = min(w.endSeconds, CMTimeGetSeconds(effectiveTrim.end))
        guard wEnd > wStart else { return nil }
        return CaptionWord(
          word: w.word,
          startSeconds: wStart - trimStart,
          endSeconds: wEnd - trimStart
        )
      }
      return CaptionSegment(
        startSeconds: overlapStart - trimStart,
        endSeconds: overlapEnd - trimStart,
        text: seg.text,
        words: remappedWords
      )
    }
  }
}
