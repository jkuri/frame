import AVFoundation
import CoreMedia
import Foundation

extension EditorState {
  func regions(for trackType: AudioTrackType) -> [AudioRegionData] {
    switch trackType {
    case .system: return systemAudioRegions
    case .mic: return micAudioRegions
    }
  }

  func setRegions(_ regions: [AudioRegionData], for trackType: AudioTrackType) {
    let sorted = regions.sorted { $0.startSeconds < $1.startSeconds }
    switch trackType {
    case .system: systemAudioRegions = sorted
    case .mic: micAudioRegions = sorted
    }
    syncAudioRegionsToPlayer()
  }

  func updateRegionStart(trackType: AudioTrackType, regionId: UUID, newStart: Double) {
    var regs = regions(for: trackType)
    guard let idx = regs.firstIndex(where: { $0.id == regionId }) else { return }
    let minStart: Double = idx > 0 ? regs[idx - 1].endSeconds : 0
    let maxStart = regs[idx].endSeconds - 0.01
    regs[idx].startSeconds = max(minStart, min(maxStart, newStart))
    setRegions(regs, for: trackType)
  }

  func updateRegionEnd(trackType: AudioTrackType, regionId: UUID, newEnd: Double) {
    var regs = regions(for: trackType)
    guard let idx = regs.firstIndex(where: { $0.id == regionId }) else { return }
    let dur = CMTimeGetSeconds(duration)
    let maxEnd: Double = idx < regs.count - 1 ? regs[idx + 1].startSeconds : dur
    let minEnd = regs[idx].startSeconds + 0.01
    regs[idx].endSeconds = max(minEnd, min(maxEnd, newEnd))
    setRegions(regs, for: trackType)
  }

  func moveRegion(trackType: AudioTrackType, regionId: UUID, newStart: Double) {
    var regs = regions(for: trackType)
    guard let idx = regs.firstIndex(where: { $0.id == regionId }) else { return }
    let dur = CMTimeGetSeconds(duration)
    let regionDuration = regs[idx].endSeconds - regs[idx].startSeconds
    let minStart: Double = idx > 0 ? regs[idx - 1].endSeconds : 0
    let maxStart: Double = (idx < regs.count - 1 ? regs[idx + 1].startSeconds : dur) - regionDuration
    let clampedStart = max(minStart, min(maxStart, newStart))
    regs[idx].startSeconds = clampedStart
    regs[idx].endSeconds = clampedStart + regionDuration
    setRegions(regs, for: trackType)
  }

  func addRegion(trackType: AudioTrackType, atTime time: Double) {
    var regs = regions(for: trackType)
    let dur = CMTimeGetSeconds(duration)
    let desiredHalf = min(5.0, dur / 2)

    var gapStart: Double = 0
    var gapEnd: Double = dur
    var insertIdx = regs.count

    for i in 0..<regs.count {
      if time < regs[i].startSeconds {
        gapEnd = regs[i].startSeconds
        insertIdx = i
        break
      }
      gapStart = regs[i].endSeconds
    }
    if insertIdx == regs.count {
      gapEnd = dur
    }

    guard gapEnd - gapStart >= 0.05 else { return }

    let regionStart = max(gapStart, time - desiredHalf)
    let regionEnd = min(gapEnd, time + desiredHalf)
    let finalStart = max(gapStart, min(regionStart, regionEnd - 0.05))
    let finalEnd = min(gapEnd, max(regionEnd, finalStart + 0.05))

    regs.insert(AudioRegionData(startSeconds: finalStart, endSeconds: finalEnd), at: insertIdx)
    setRegions(regs, for: trackType)
  }

  func removeRegion(trackType: AudioTrackType, regionId: UUID) {
    var regs = regions(for: trackType)
    regs.removeAll { $0.id == regionId }
    setRegions(regs, for: trackType)
  }

  func syncAudioRegionsToPlayer() {
    playerController.systemAudioRegions = systemAudioRegions.map { region in
      (
        start: CMTime(seconds: region.startSeconds, preferredTimescale: 600),
        end: CMTime(seconds: region.endSeconds, preferredTimescale: 600)
      )
    }
    playerController.micAudioRegions = micAudioRegions.map { region in
      (
        start: CMTime(seconds: region.startSeconds, preferredTimescale: 600),
        end: CMTime(seconds: region.endSeconds, preferredTimescale: 600)
      )
    }
    syncVideoRegionsToPlayer()
  }

  func syncVideoRegionsToPlayer() {
    playerController.videoRegions = videoRegions.map { (start: $0.startSeconds, end: $0.endSeconds) }
  }

  func syncAudioVolumes() {
    playerController.setSystemAudioVolume(effectiveSystemAudioVolume)
    playerController.setMicAudioVolume(effectiveMicAudioVolume)
  }

  func syncNoiseReduction() {
    regenerateProcessedMicAudio()
  }

  func regenerateProcessedMicAudio() {
    micProcessingTask?.cancel()
    guard let micURL = result.microphoneAudioURL, micNoiseReductionEnabled else {
      if let old = processedMicAudioURL {
        if !isURLInsideProjectBundle(old) {
          try? FileManager.default.removeItem(at: old)
        }
        processedMicAudioURL = nil
      }
      isMicProcessing = false
      if let micURL = result.microphoneAudioURL {
        playerController.swapMicAudioFile(url: micURL)
      }
      return
    }

    let intensity = micNoiseReductionIntensity

    if let proj = project,
      let cachedURL = proj.denoisedMicAudioURL,
      let cachedIntensity = proj.metadata.editorState?.audioSettings?.cachedNoiseReductionIntensity,
      abs(cachedIntensity - intensity) < 0.001
    {
      let oldURL = processedMicAudioURL
      processedMicAudioURL = cachedURL
      isMicProcessing = false
      playerController.swapMicAudioFile(url: cachedURL)
      if let oldURL, oldURL != cachedURL, !isURLInsideProjectBundle(oldURL) {
        try? FileManager.default.removeItem(at: oldURL)
      }
      return
    }

    isMicProcessing = true
    micProcessingProgress = 0
    let state = self
    micProcessingTask = Task {
      try? await Task.sleep(for: .milliseconds(500))
      guard !Task.isCancelled else { return }

      let tempURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("reframed-nr-preview-\(UUID().uuidString).m4a")

      do {
        try await RNNoiseProcessor.processFile(
          inputURL: micURL,
          outputURL: tempURL,
          intensity: intensity,
          onProgress: { progress in
            state.micProcessingProgress = progress
          }
        )
        guard !Task.isCancelled else {
          try? FileManager.default.removeItem(at: tempURL)
          return
        }

        var finalURL = tempURL
        if let proj = state.project {
          let destURL = proj.denoisedMicAudioDestinationURL
          try? FileManager.default.removeItem(at: destURL)
          do {
            try FileManager.default.copyItem(at: tempURL, to: destURL)
            try? FileManager.default.removeItem(at: tempURL)
            finalURL = destURL
          } catch {
            state.logger.warning("Failed to cache denoised audio in bundle: \(error)")
          }
        }

        let oldURL = state.processedMicAudioURL
        state.processedMicAudioURL = finalURL
        state.isMicProcessing = false
        state.playerController.swapMicAudioFile(url: finalURL)
        if let oldURL, oldURL != finalURL, !state.isURLInsideProjectBundle(oldURL) {
          try? FileManager.default.removeItem(at: oldURL)
        }
        state.scheduleSave()
      } catch {
        guard !Task.isCancelled else {
          try? FileManager.default.removeItem(at: tempURL)
          return
        }
        state.isMicProcessing = false
        state.logger.error("Mic noise reduction failed: \(error)")
      }
    }
  }

  func isURLInsideProjectBundle(_ url: URL) -> Bool {
    guard let bundleURL = project?.bundleURL else { return false }
    return url.path.hasPrefix(bundleURL.path)
  }
}
