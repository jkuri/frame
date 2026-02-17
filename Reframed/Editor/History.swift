import Foundation

struct HistoryEntry: Codable, Sendable {
  var snapshot: EditorStateData
  var timestamp: Date
}

struct HistoryData: Codable, Sendable {
  var entries: [HistoryEntry]
  var currentIndex: Int
}

@MainActor
@Observable
final class History {
  private(set) var entries: [HistoryEntry] = []
  private(set) var currentIndex: Int = -1

  private let maxSnapshots = 50

  var canUndo: Bool { currentIndex > 0 }
  var canRedo: Bool { currentIndex < entries.count - 1 }

  func pushSnapshot(_ snapshot: EditorStateData) {
    if currentIndex < entries.count - 1 {
      entries.removeSubrange((currentIndex + 1)...)
    }
    entries.append(HistoryEntry(snapshot: snapshot, timestamp: Date()))
    currentIndex = entries.count - 1
    if entries.count > maxSnapshots {
      let excess = entries.count - maxSnapshots
      entries.removeFirst(excess)
      currentIndex -= excess
    }
  }

  func undo() -> EditorStateData? {
    guard canUndo else { return nil }
    currentIndex -= 1
    return entries[currentIndex].snapshot
  }

  func redo() -> EditorStateData? {
    guard canRedo else { return nil }
    currentIndex += 1
    return entries[currentIndex].snapshot
  }

  func jumpTo(index: Int) -> EditorStateData? {
    guard index >= 0 && index < entries.count else { return nil }
    currentIndex = index
    return entries[index].snapshot
  }

  func load(from data: HistoryData) {
    entries = data.entries
    currentIndex = min(data.currentIndex, entries.count - 1)
    if entries.count > maxSnapshots {
      let excess = entries.count - maxSnapshots
      entries.removeFirst(excess)
      currentIndex -= excess
    }
    if currentIndex < 0 && !entries.isEmpty {
      currentIndex = 0
    }
  }

  func toData() -> HistoryData {
    HistoryData(entries: entries, currentIndex: currentIndex)
  }

  static func describeChanges(from old: EditorStateData, to new: EditorStateData) -> [String] {
    var changes: [String] = []

    if old.trimStartSeconds != new.trimStartSeconds || old.trimEndSeconds != new.trimEndSeconds {
      changes.append(
        "Trim range: \(String(format: "%.1f", old.trimStartSeconds))s–\(String(format: "%.1f", old.trimEndSeconds))s → \(String(format: "%.1f", new.trimStartSeconds))s–\(String(format: "%.1f", new.trimEndSeconds))s"
      )
    }

    if old.backgroundStyle != new.backgroundStyle {
      changes.append("Background changed")
    }

    if old.backgroundImageFillMode != new.backgroundImageFillMode {
      changes.append("Background fill mode changed")
    }

    if old.canvasAspect != new.canvasAspect {
      let oldLabel = (old.canvasAspect ?? .original).label
      let newLabel = (new.canvasAspect ?? .original).label
      changes.append("Canvas aspect: \(oldLabel) → \(newLabel)")
    }

    if old.padding != new.padding {
      changes.append("Padding: \(String(format: "%.2f", old.padding)) → \(String(format: "%.2f", new.padding))")
    }

    if old.videoCornerRadius != new.videoCornerRadius {
      changes.append(
        "Video corner radius: \(String(format: "%.0f", old.videoCornerRadius)) → \(String(format: "%.0f", new.videoCornerRadius))"
      )
    }

    if old.cameraAspect != new.cameraAspect {
      let oldLabel = (old.cameraAspect ?? .original).label
      let newLabel = (new.cameraAspect ?? .original).label
      changes.append("Camera aspect: \(oldLabel) → \(newLabel)")
    }

    if old.cameraCornerRadius != new.cameraCornerRadius {
      changes.append(
        "Camera corner radius: \(String(format: "%.0f", old.cameraCornerRadius)) → \(String(format: "%.0f", new.cameraCornerRadius))"
      )
    }

    if old.cameraBorderWidth != new.cameraBorderWidth {
      changes.append(
        "Camera border width: \(String(format: "%.1f", old.cameraBorderWidth)) → \(String(format: "%.1f", new.cameraBorderWidth))"
      )
    }

    if old.cameraBorderColor != new.cameraBorderColor {
      changes.append("Camera border color changed")
    }

    if old.videoShadow != new.videoShadow {
      changes.append(
        "Video shadow: \(String(format: "%.0f", old.videoShadow ?? 0)) → \(String(format: "%.0f", new.videoShadow ?? 0))"
      )
    }

    if old.cameraShadow != new.cameraShadow {
      changes.append(
        "Camera shadow: \(String(format: "%.0f", old.cameraShadow ?? 0)) → \(String(format: "%.0f", new.cameraShadow ?? 0))"
      )
    }

    if old.cameraMirrored != new.cameraMirrored {
      let enabled = (new.cameraMirrored ?? false)
      changes.append("Camera mirrored \(enabled ? "enabled" : "disabled")")
    }

    if old.cameraLayout != new.cameraLayout {
      changes.append("Camera position changed")
    }

    if old.webcamEnabled != new.webcamEnabled {
      let enabled = (new.webcamEnabled ?? true)
      changes.append("Webcam \(enabled ? "enabled" : "disabled")")
    }

    if old.cursorSettings != new.cursorSettings {
      describeCursorChanges(from: old.cursorSettings, to: new.cursorSettings, into: &changes)
    }

    if old.zoomSettings != new.zoomSettings {
      describeZoomChanges(from: old.zoomSettings, to: new.zoomSettings, into: &changes)
    }

    if old.animationSettings != new.animationSettings {
      describeAnimationChanges(from: old.animationSettings, to: new.animationSettings, into: &changes)
    }

    if old.audioSettings != new.audioSettings {
      describeAudioChanges(from: old.audioSettings, to: new.audioSettings, into: &changes)
    }

    if old.systemAudioRegions != new.systemAudioRegions {
      changes.append("System audio regions changed")
    }

    if old.micAudioRegions != new.micAudioRegions {
      changes.append("Mic audio regions changed")
    }

    if old.cameraFullscreenRegions != new.cameraFullscreenRegions {
      changes.append("Camera regions changed")
    }

    return changes
  }

  private static func describeCursorChanges(
    from old: CursorSettingsData?,
    to new: CursorSettingsData?,
    into changes: inout [String]
  ) {
    let oldShow = old?.showCursor ?? true
    let newShow = new?.showCursor ?? true
    if oldShow != newShow {
      changes.append("Show cursor \(newShow ? "enabled" : "disabled")")
      return
    }

    if old?.cursorStyleRaw != new?.cursorStyleRaw {
      changes.append("Cursor style changed")
    }
    if old?.cursorSize != new?.cursorSize {
      changes.append(
        "Cursor size: \(String(format: "%.0f", old?.cursorSize ?? 24)) → \(String(format: "%.0f", new?.cursorSize ?? 24))"
      )
    }
    if old?.showClickHighlights != new?.showClickHighlights {
      let enabled = new?.showClickHighlights ?? false
      changes.append("Click highlights \(enabled ? "enabled" : "disabled")")
    }
    if old?.clickHighlightColor != new?.clickHighlightColor
      || old?.clickHighlightSize != new?.clickHighlightSize
    {
      if old?.showClickHighlights == new?.showClickHighlights {
        changes.append("Click highlight style changed")
      }
    }
  }

  private static func describeZoomChanges(
    from old: ZoomSettingsData?,
    to new: ZoomSettingsData?,
    into changes: inout [String]
  ) {
    if old?.zoomEnabled != new?.zoomEnabled {
      let enabled = new?.zoomEnabled ?? false
      changes.append("Zoom \(enabled ? "enabled" : "disabled")")
    }
    if old?.autoZoomEnabled != new?.autoZoomEnabled {
      let enabled = new?.autoZoomEnabled ?? false
      changes.append("Auto zoom \(enabled ? "enabled" : "disabled")")
    }
    if old?.zoomLevel != new?.zoomLevel {
      changes.append(
        "Zoom level: \(String(format: "%.1f", old?.zoomLevel ?? 2.0))x → \(String(format: "%.1f", new?.zoomLevel ?? 2.0))x"
      )
    }
    if old?.keyframes != new?.keyframes {
      changes.append("Zoom keyframes changed")
    }
  }

  private static func describeAnimationChanges(
    from old: AnimationSettingsData?,
    to new: AnimationSettingsData?,
    into changes: inout [String]
  ) {
    if old?.cursorMovementEnabled != new?.cursorMovementEnabled {
      let enabled = new?.cursorMovementEnabled ?? false
      changes.append("Cursor animation \(enabled ? "enabled" : "disabled")")
    }
    if old?.cursorMovementSpeed != new?.cursorMovementSpeed {
      changes.append("Cursor animation speed changed")
    }
  }

  private static func describeAudioChanges(
    from old: AudioSettingsData?,
    to new: AudioSettingsData?,
    into changes: inout [String]
  ) {
    if old?.systemAudioVolume != new?.systemAudioVolume
      || old?.systemAudioMuted != new?.systemAudioMuted
    {
      let oldVol = old?.systemAudioMuted == true ? 0 : Int((old?.systemAudioVolume ?? 1.0) * 100)
      let newVol = new?.systemAudioMuted == true ? 0 : Int((new?.systemAudioVolume ?? 1.0) * 100)
      changes.append("System audio volume: \(oldVol)% → \(newVol)%")
    }
    if old?.micAudioVolume != new?.micAudioVolume || old?.micAudioMuted != new?.micAudioMuted {
      let oldVol = old?.micAudioMuted == true ? 0 : Int((old?.micAudioVolume ?? 1.0) * 100)
      let newVol = new?.micAudioMuted == true ? 0 : Int((new?.micAudioVolume ?? 1.0) * 100)
      changes.append("Mic audio volume: \(oldVol)% → \(newVol)%")
    }
    if old?.micNoiseReductionEnabled != new?.micNoiseReductionEnabled {
      let enabled = new?.micNoiseReductionEnabled ?? false
      changes.append("Noise reduction \(enabled ? "enabled" : "disabled")")
    }
    if old?.micNoiseReductionIntensity != new?.micNoiseReductionIntensity {
      changes.append(
        "Noise reduction intensity: \(Int((old?.micNoiseReductionIntensity ?? 0.5) * 100))% → \(Int((new?.micNoiseReductionIntensity ?? 0.5) * 100))%"
      )
    }
  }
}
