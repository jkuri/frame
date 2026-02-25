import CoreMedia
import Foundation

extension EditorState {
  func isCameraFullscreen(at time: Double) -> Bool {
    cameraRegions.contains { $0.type == .fullscreen && time >= $0.startSeconds && time <= $0.endSeconds }
  }

  func isCameraHidden(at time: Double) -> Bool {
    cameraRegions.contains { $0.type == .hidden && time >= $0.startSeconds && time <= $0.endSeconds }
  }

  func effectiveCameraLayout(at time: Double) -> CameraLayout {
    if let region = cameraRegions.first(where: {
      $0.type == .custom && time >= $0.startSeconds && time <= $0.endSeconds
    }), let layout = region.customLayout {
      return layout
    }
    return cameraLayout
  }

  func activeCameraRegionId(at time: Double) -> UUID? {
    cameraRegions.first(where: {
      $0.type == .custom && time >= $0.startSeconds && time <= $0.endSeconds
    })?.id
  }

  func updateCameraRegionLayout(regionId: UUID, layout: CameraLayout) {
    guard let idx = cameraRegions.firstIndex(where: { $0.id == regionId }) else { return }
    cameraRegions[idx].customLayout = layout
  }

  func setCameraRegionCorner(regionId: UUID, corner: CameraCorner) {
    guard let idx = cameraRegions.firstIndex(where: { $0.id == regionId }),
      var layout = cameraRegions[idx].customLayout
    else { return }
    let regionAspect = cameraRegions[idx].customCameraAspect ?? cameraAspect
    let margin: CGFloat = 0.02
    let canvas = canvasSize(for: result.screenSize)
    let marginY = margin * canvas.width / max(canvas.height, 1)
    let relH: CGFloat = {
      guard let ws = result.webcamSize else { return layout.relativeWidth * 0.75 }
      let aspect = regionAspect.heightToWidthRatio(webcamSize: ws)
      return layout.relativeWidth * aspect * (canvas.width / max(canvas.height, 1))
    }()
    switch corner {
    case .topLeft:
      layout.relativeX = margin
      layout.relativeY = marginY
    case .topRight:
      layout.relativeX = 1.0 - layout.relativeWidth - margin
      layout.relativeY = marginY
    case .bottomLeft:
      layout.relativeX = margin
      layout.relativeY = 1.0 - relH - marginY
    case .bottomRight:
      layout.relativeX = 1.0 - layout.relativeWidth - margin
      layout.relativeY = 1.0 - relH - marginY
    }
    cameraRegions[idx].customLayout = layout
  }

  func clampCameraRegionLayout(regionId: UUID) {
    guard let idx = cameraRegions.firstIndex(where: { $0.id == regionId }),
      var layout = cameraRegions[idx].customLayout
    else { return }
    let regionAspect = cameraRegions[idx].customCameraAspect ?? cameraAspect
    layout.relativeWidth = min(layout.relativeWidth, maxCameraRelativeWidth(for: regionAspect))
    let relH: CGFloat = {
      guard let ws = result.webcamSize else { return layout.relativeWidth * 0.75 }
      let canvas = canvasSize(for: result.screenSize)
      let aspect = regionAspect.heightToWidthRatio(webcamSize: ws)
      return layout.relativeWidth * aspect * (canvas.width / max(canvas.height, 1))
    }()
    layout.relativeX = max(0, min(1 - layout.relativeWidth, layout.relativeX))
    layout.relativeY = max(0, min(1 - relH, layout.relativeY))
    cameraRegions[idx].customLayout = layout
  }

  func updateCameraRegionStyle(
    regionId: UUID,
    aspect: CameraAspect? = nil,
    cornerRadius: CGFloat? = nil,
    shadow: CGFloat? = nil,
    borderWidth: CGFloat? = nil,
    borderColor: CodableColor? = nil,
    mirrored: Bool? = nil
  ) {
    guard let idx = cameraRegions.firstIndex(where: { $0.id == regionId }) else { return }
    if let aspect { cameraRegions[idx].customCameraAspect = aspect }
    if let cornerRadius { cameraRegions[idx].customCornerRadius = cornerRadius }
    if let shadow { cameraRegions[idx].customShadow = shadow }
    if let borderWidth { cameraRegions[idx].customBorderWidth = borderWidth }
    if let borderColor { cameraRegions[idx].customBorderColor = borderColor }
    if let mirrored { cameraRegions[idx].customMirrored = mirrored }
    if aspect != nil {
      clampCameraRegionLayout(regionId: regionId)
    }
  }

  func updateCameraRegionTransition(
    regionId: UUID,
    entryTransition: RegionTransitionType? = nil,
    entryDuration: Double? = nil,
    exitTransition: RegionTransitionType? = nil,
    exitDuration: Double? = nil
  ) {
    guard let idx = cameraRegions.firstIndex(where: { $0.id == regionId }) else { return }
    if let entryTransition { cameraRegions[idx].entryTransition = entryTransition }
    if let entryDuration { cameraRegions[idx].entryTransitionDuration = entryDuration }
    if let exitTransition { cameraRegions[idx].exitTransition = exitTransition }
    if let exitDuration { cameraRegions[idx].exitTransitionDuration = exitDuration }
  }

  func addCameraRegion(atTime time: Double, type: CameraRegionType = .fullscreen) {
    let dur = CMTimeGetSeconds(duration)
    let desiredHalf = min(5.0, dur / 2)
    var gapStart: Double = 0
    var gapEnd: Double = dur
    var insertIdx = cameraRegions.count

    for i in 0..<cameraRegions.count {
      if time < cameraRegions[i].startSeconds {
        gapEnd = cameraRegions[i].startSeconds
        insertIdx = i
        break
      }
      gapStart = cameraRegions[i].endSeconds
    }
    if insertIdx == cameraRegions.count {
      gapEnd = dur
    }

    guard gapEnd - gapStart >= 0.05 else { return }

    let regionStart = max(gapStart, time - desiredHalf)
    let regionEnd = min(gapEnd, time + desiredHalf)
    let finalStart = max(gapStart, min(regionStart, regionEnd - 0.05))
    let finalEnd = min(gapEnd, max(regionEnd, finalStart + 0.05))

    cameraRegions.insert(
      CameraRegionData(startSeconds: finalStart, endSeconds: finalEnd, type: type),
      at: insertIdx
    )
    cameraRegions.sort { $0.startSeconds < $1.startSeconds }
  }

  func removeCameraRegion(regionId: UUID) {
    cameraRegions.removeAll { $0.id == regionId }
  }

  func updateCameraRegionType(regionId: UUID, type: CameraRegionType) {
    guard let idx = cameraRegions.firstIndex(where: { $0.id == regionId }) else { return }
    cameraRegions[idx].type = type
    if type == .custom {
      if cameraRegions[idx].customLayout == nil {
        cameraRegions[idx].customLayout = cameraLayout
      }
      if cameraRegions[idx].customCameraAspect == nil {
        cameraRegions[idx].customCameraAspect = cameraAspect
      }
      if cameraRegions[idx].customCornerRadius == nil {
        cameraRegions[idx].customCornerRadius = cameraCornerRadius
      }
      if cameraRegions[idx].customShadow == nil {
        cameraRegions[idx].customShadow = cameraShadow
      }
      if cameraRegions[idx].customBorderWidth == nil {
        cameraRegions[idx].customBorderWidth = cameraBorderWidth
      }
      if cameraRegions[idx].customBorderColor == nil {
        cameraRegions[idx].customBorderColor = cameraBorderColor
      }
      if cameraRegions[idx].customMirrored == nil {
        cameraRegions[idx].customMirrored = cameraMirrored
      }
    }
  }

  func updateCameraRegionStart(regionId: UUID, newStart: Double) {
    guard let idx = cameraRegions.firstIndex(where: { $0.id == regionId }) else { return }
    let minStart: Double = idx > 0 ? cameraRegions[idx - 1].endSeconds : 0
    let maxStart = cameraRegions[idx].endSeconds - 0.01
    cameraRegions[idx].startSeconds = max(minStart, min(maxStart, newStart))
    cameraRegions.sort { $0.startSeconds < $1.startSeconds }
  }

  func updateCameraRegionEnd(regionId: UUID, newEnd: Double) {
    guard let idx = cameraRegions.firstIndex(where: { $0.id == regionId }) else { return }
    let dur = CMTimeGetSeconds(duration)
    let maxEnd: Double =
      idx < cameraRegions.count - 1
      ? cameraRegions[idx + 1].startSeconds : dur
    let minEnd = cameraRegions[idx].startSeconds + 0.01
    cameraRegions[idx].endSeconds = max(minEnd, min(maxEnd, newEnd))
    cameraRegions.sort { $0.startSeconds < $1.startSeconds }
  }

  func moveCameraRegion(regionId: UUID, newStart: Double) {
    guard let idx = cameraRegions.firstIndex(where: { $0.id == regionId }) else { return }
    let dur = CMTimeGetSeconds(duration)
    let regionDuration = cameraRegions[idx].endSeconds - cameraRegions[idx].startSeconds
    let minStart: Double = idx > 0 ? cameraRegions[idx - 1].endSeconds : 0
    let maxStart: Double =
      (idx < cameraRegions.count - 1
        ? cameraRegions[idx + 1].startSeconds : dur) - regionDuration
    let clampedStart = max(minStart, min(maxStart, newStart))
    cameraRegions[idx].startSeconds = clampedStart
    cameraRegions[idx].endSeconds = clampedStart + regionDuration
    cameraRegions.sort { $0.startSeconds < $1.startSeconds }
  }
}
