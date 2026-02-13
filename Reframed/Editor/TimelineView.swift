import AVFoundation
import SwiftUI

struct TimelineView: View {
  @Bindable var editorState: EditorState
  let systemAudioSamples: [Float]
  let micAudioSamples: [Float]
  let onScrub: (CMTime) -> Void

  private let sidebarWidth: CGFloat = 70
  private let rulerHeight: CGFloat = 28
  private let trackHeight: CGFloat = 42

  private var totalSeconds: Double {
    max(CMTimeGetSeconds(editorState.duration), 0.001)
  }

  private var playheadFraction: Double {
    CMTimeGetSeconds(editorState.currentTime) / totalSeconds
  }

  private var videoTrimStart: Double {
    CMTimeGetSeconds(editorState.trimStart) / totalSeconds
  }

  private var videoTrimEnd: Double {
    CMTimeGetSeconds(editorState.trimEnd) / totalSeconds
  }

  private var sysAudioTrimStart: Double {
    CMTimeGetSeconds(editorState.systemAudioTrimStart) / totalSeconds
  }

  private var sysAudioTrimEnd: Double {
    CMTimeGetSeconds(editorState.systemAudioTrimEnd) / totalSeconds
  }

  private var micAudioTrimStart: Double {
    CMTimeGetSeconds(editorState.micAudioTrimStart) / totalSeconds
  }

  private var micAudioTrimEnd: Double {
    CMTimeGetSeconds(editorState.micAudioTrimEnd) / totalSeconds
  }

  var body: some View {
    ZStack(alignment: .top) {
      VStack(spacing: 0) {
        HStack(spacing: 0) {
          Color.clear
            .frame(width: sidebarWidth, height: rulerHeight)
          timeRuler
            .padding(.trailing, 8)
        }

        VStack(spacing: 10) {
          trackLane(
            label: "Screen",
            icon: "display",
            rowIndex: 0,

            content: { width, height in videoTrackBackground(width: width, height: height, trimStart: videoTrimStart, trimEnd: videoTrimEnd) },
            trimStart: videoTrimStart,
            trimEnd: videoTrimEnd,
            onTrimStart: { f in
              editorState.updateTrimStart(CMTime(seconds: max(0, f) * totalSeconds, preferredTimescale: 600))
            },
            onTrimEnd: { f in
              editorState.updateTrimEnd(CMTime(seconds: min(1, f) * totalSeconds, preferredTimescale: 600))
            }
          )

          if editorState.hasWebcam {
            trackLane(
              label: "Camera",
              icon: "web.camera",
              rowIndex: 1,

              content: { width, height in videoTrackBackground(width: width, height: height, isWebcam: true, trimStart: videoTrimStart, trimEnd: videoTrimEnd) },
              trimStart: videoTrimStart,
              trimEnd: videoTrimEnd,
              onTrimStart: { f in
                editorState.updateTrimStart(CMTime(seconds: max(0, f) * totalSeconds, preferredTimescale: 600))
              },
              onTrimEnd: { f in
                editorState.updateTrimEnd(CMTime(seconds: min(1, f) * totalSeconds, preferredTimescale: 600))
              }
            )
          }

          if !systemAudioSamples.isEmpty {
            trackLane(
              label: "System",
              icon: "speaker.wave.2",
              rowIndex: editorState.hasWebcam ? 2 : 1,
              borderColor: ReframedColors.systemAudioColor,
              content: { width, height in
                audioClipContent(
                  samples: systemAudioSamples,
                  trimStart: sysAudioTrimStart,
                  trimEnd: sysAudioTrimEnd,
                  width: width,
                  height: height,
                  accentColor: ReframedColors.systemAudioColor
                )
              },
              trimStart: sysAudioTrimStart,
              trimEnd: sysAudioTrimEnd,
              onTrimStart: { f in
                editorState.updateSystemAudioTrimStart(CMTime(seconds: max(0, f) * totalSeconds, preferredTimescale: 600))
              },
              onTrimEnd: { f in
                editorState.updateSystemAudioTrimEnd(CMTime(seconds: min(1, f) * totalSeconds, preferredTimescale: 600))
              }
            )
          }

          if !micAudioSamples.isEmpty {
            trackLane(
              label: "Mic",
              icon: "mic",
              rowIndex: {
                var idx = 1
                if editorState.hasWebcam { idx += 1 }
                if !systemAudioSamples.isEmpty { idx += 1 }
                return idx
              }(),
              borderColor: ReframedColors.micAudioColor,
              content: { width, height in
                audioClipContent(
                  samples: micAudioSamples,
                  trimStart: micAudioTrimStart,
                  trimEnd: micAudioTrimEnd,
                  width: width,
                  height: height,
                  accentColor: ReframedColors.micAudioColor
                )
              },
              trimStart: micAudioTrimStart,
              trimEnd: micAudioTrimEnd,
              onTrimStart: { f in
                editorState.updateMicAudioTrimStart(CMTime(seconds: max(0, f) * totalSeconds, preferredTimescale: 600))
              },
              onTrimEnd: { f in
                editorState.updateMicAudioTrimEnd(CMTime(seconds: min(1, f) * totalSeconds, preferredTimescale: 600))
              }
            )
          }

          if editorState.zoomEnabled {
            zoomTrackLane(keyframes: editorState.zoomTimeline?.allKeyframes ?? [])
          }
        }
      }

      playheadOverlay
    }
    .background(ReframedColors.panelBackground)
    .padding(.vertical, 8)
  }

  // MARK: - Time Ruler

  private var timeRuler: some View {
    GeometryReader { geo in
      let width = geo.size.width
      Canvas { context, size in
        let duration = totalSeconds
        let interval = rulerInterval(for: duration)
        let minorInterval = interval / 5

        var t: Double = 0
        while t <= duration {
          let x = CGFloat(t / duration) * size.width
          let isMajor = isApproximatelyMultiple(t, of: interval)

          if isMajor {
            let tickPath = Path { p in
              p.move(to: CGPoint(x: x, y: size.height - 10))
              p.addLine(to: CGPoint(x: x, y: size.height))
            }
            context.stroke(tickPath, with: .color(ReframedColors.tertiaryText), lineWidth: 1)

            let label = formatRulerTime(t)
            let text = Text(label)
              .font(.system(size: 9, design: .monospaced))
              .foregroundStyle(ReframedColors.secondaryText)
            context.draw(context.resolve(text), at: CGPoint(x: x, y: size.height - 16), anchor: .bottom)
          } else {
            let tickPath = Path { p in
              p.move(to: CGPoint(x: x, y: size.height - 5))
              p.addLine(to: CGPoint(x: x, y: size.height))
            }
            context.stroke(tickPath, with: .color(ReframedColors.tertiaryText.opacity(0.5)), lineWidth: 0.5)
          }
          t += minorInterval
        }
      }
      .frame(height: rulerHeight)
      .background(ReframedColors.panelBackground)
      .contentShape(Rectangle())
      .gesture(rulerScrubGesture(width: width))
    }
    .frame(height: rulerHeight)
  }

  private func rulerInterval(for duration: Double) -> Double {
    if duration <= 5 { return 1 }
    if duration <= 15 { return 2 }
    if duration <= 30 { return 5 }
    if duration <= 60 { return 10 }
    if duration <= 180 { return 30 }
    if duration <= 600 { return 60 }
    return 120
  }

  private func isApproximatelyMultiple(_ value: Double, of interval: Double) -> Bool {
    let remainder = value.truncatingRemainder(dividingBy: interval)
    return remainder < 0.001 || (interval - remainder) < 0.001
  }

  private func formatRulerTime(_ seconds: Double) -> String {
    let mins = Int(seconds) / 60
    let secs = Int(seconds) % 60
    if totalSeconds >= 60 {
      return String(format: "%d:%02d", mins, secs)
    }
    return String(format: "0:%02d", secs)
  }

  private func rulerScrubGesture(width: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        let fraction = max(0, min(1, value.location.x / width))
        let time = CMTime(seconds: fraction * totalSeconds, preferredTimescale: 600)
        onScrub(time)
      }
  }

  // MARK: - Track Lane

  private func trackLane<Content: View>(
    label: String,
    icon: String,
    rowIndex: Int,
    borderColor: Color = ReframedColors.controlAccentColor,
    @ViewBuilder content: @escaping (CGFloat, CGFloat) -> Content,
    trimStart: Double,
    trimEnd: Double,
    onTrimStart: @escaping (Double) -> Void,
    onTrimEnd: @escaping (Double) -> Void
  ) -> some View {
    HStack(spacing: 0) {
      trackSidebar(label: label, icon: icon)
        .frame(width: sidebarWidth)

      GeometryReader { geo in
        let width = geo.size.width
        let h = geo.size.height

        ZStack(alignment: .leading) {
          content(width, h)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
          trimBorderOverlay(width: width, height: h, trimStart: trimStart, trimEnd: trimEnd, borderColor: borderColor)
        }
        .contentShape(Rectangle())
        .coordinateSpace(name: "timeline")
        .overlay {
          trimHandleOverlay(
            width: width,
            height: h,
            trimStart: trimStart,
            trimEnd: trimEnd,
            onTrimStart: onTrimStart,
            onTrimEnd: onTrimEnd
          )
        }
      }
      .padding(.trailing, 8)
    }
    .frame(height: trackHeight)
    .background(ReframedColors.panelBackground)
  }

  private func trackSidebar(label: String, icon: String) -> some View {
    VStack(spacing: 2) {
      Image(systemName: icon)
        .font(.system(size: 12))
      Text(label)
        .font(.system(size: 9))
    }
    .foregroundStyle(ReframedColors.secondaryText)
  }

  // MARK: - Video Content

  private func videoTrackBackground(width: CGFloat, height: CGFloat, isWebcam: Bool = false, trimStart: Double, trimEnd: Double) -> some View {
    let startX = width * trimStart
    let trimWidth = width * (trimEnd - trimStart)

    return ZStack(alignment: .leading) {
      Color.clear
        .frame(width: width, height: height)

      RoundedRectangle(cornerRadius: 10)
        .fill(
          LinearGradient(
            colors: isWebcam ? ReframedColors.webcamTrackGradient : ReframedColors.screenTrackGradient,
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .frame(width: max(0, trimWidth), height: height)
        .offset(x: startX)
    }
    .frame(width: width, height: height)
  }

  // MARK: - Audio Content

  private func audioClipContent(
    samples: [Float],
    trimStart: Double,
    trimEnd: Double,
    width: CGFloat,
    height: CGFloat,
    accentColor: Color
  ) -> some View {
    ZStack(alignment: .leading) {
      Color.clear

      RoundedRectangle(cornerRadius: 10)
        .fill(accentColor.opacity(0.1))
        .frame(width: max(0, width * (trimEnd - trimStart)), height: height)
        .offset(x: width * trimStart)

      waveformView(samples: samples, trimStart: trimStart, trimEnd: trimEnd, width: width, height: height, accentColor: accentColor)
    }
    .frame(width: width, height: height)
  }

  // MARK: - Waveform

  private func waveformView(samples: [Float], trimStart: Double, trimEnd: Double, width: CGFloat, height: CGFloat, accentColor: Color) -> some View {
    Canvas { context, size in
      let count = samples.count
      guard count > 0 else { return }
      let midY = size.height / 2
      let maxAmp = size.height * 0.4
      let step = size.width / CGFloat(count - 1)
      let trimStartX = size.width * trimStart
      let trimEndX = size.width * trimEnd

      var topPoints: [CGPoint] = []
      var bottomPoints: [CGPoint] = []
      for i in 0..<count {
        let x = CGFloat(i) * step
        let amp = CGFloat(samples[i]) * maxAmp
        topPoints.append(CGPoint(x: x, y: midY - amp))
        bottomPoints.append(CGPoint(x: x, y: midY + amp))
      }

      let activeShape = buildWaveformPath(top: topPoints, bottom: bottomPoints, minX: trimStartX, maxX: trimEndX)
      let inactiveLeftShape = buildWaveformPath(top: topPoints, bottom: bottomPoints, minX: 0, maxX: trimStartX)
      let inactiveRightShape = buildWaveformPath(top: topPoints, bottom: bottomPoints, minX: trimEndX, maxX: size.width)

      context.fill(activeShape, with: .color(accentColor))
      context.fill(inactiveLeftShape, with: .color(ReframedColors.tertiaryText.opacity(0.4)))
      context.fill(inactiveRightShape, with: .color(ReframedColors.tertiaryText.opacity(0.4)))
    }
    .allowsHitTesting(false)
  }

  private func buildWaveformPath(top: [CGPoint], bottom: [CGPoint], minX: CGFloat, maxX: CGFloat) -> Path {
    guard top.count > 1, maxX > minX else { return Path() }
    let step = top.count > 1 ? top[1].x - top[0].x : 1

    var clippedTop: [CGPoint] = []
    var clippedBottom: [CGPoint] = []

    for i in 0..<top.count {
      let x = top[i].x
      if x >= minX - step && x <= maxX + step {
        let cx = max(minX, min(maxX, x))
        if x != cx {
          let t: CGFloat
          if i > 0 && x < minX {
            t = (minX - top[i].x) / step
            let ty = top[i].y + (top[min(i + 1, top.count - 1)].y - top[i].y) * t
            let by = bottom[i].y + (bottom[min(i + 1, bottom.count - 1)].y - bottom[i].y) * t
            clippedTop.append(CGPoint(x: minX, y: ty))
            clippedBottom.append(CGPoint(x: minX, y: by))
          } else if x > maxX {
            t = (maxX - top[max(i - 1, 0)].x) / step
            let ty = top[max(i - 1, 0)].y + (top[i].y - top[max(i - 1, 0)].y) * t
            let by = bottom[max(i - 1, 0)].y + (bottom[i].y - bottom[max(i - 1, 0)].y) * t
            clippedTop.append(CGPoint(x: maxX, y: ty))
            clippedBottom.append(CGPoint(x: maxX, y: by))
          }
        } else {
          clippedTop.append(top[i])
          clippedBottom.append(bottom[i])
        }
      }
    }

    guard clippedTop.count > 1 else { return Path() }

    var path = Path()
    path.move(to: clippedTop[0])
    for i in 1..<clippedTop.count {
      let prev = clippedTop[i - 1]
      let curr = clippedTop[i]
      let mx = (prev.x + curr.x) / 2
      path.addCurve(to: curr, control1: CGPoint(x: mx, y: prev.y), control2: CGPoint(x: mx, y: curr.y))
    }
    for i in stride(from: clippedBottom.count - 1, through: 0, by: -1) {
      let curr = clippedBottom[i]
      if i == clippedBottom.count - 1 {
        path.addLine(to: curr)
      } else {
        let prev = clippedBottom[i + 1]
        let mx = (prev.x + curr.x) / 2
        path.addCurve(to: curr, control1: CGPoint(x: mx, y: prev.y), control2: CGPoint(x: mx, y: curr.y))
      }
    }
    path.closeSubpath()
    return path
  }

  // MARK: - Zoom Track

  private func zoomTrackLane(keyframes: [ZoomKeyframe]) -> some View {
    HStack(spacing: 0) {
      trackSidebar(label: "Zoom", icon: "plus.magnifyingglass")
        .frame(width: sidebarWidth)

      GeometryReader { geo in
        ZoomKeyframeEditor(
          keyframes: keyframes,
          duration: totalSeconds,
          width: geo.size.width,
          height: geo.size.height,
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
      }
      .padding(.trailing, 8)
    }
    .frame(height: trackHeight)
    .background(ReframedColors.panelBackground)
  }

  // MARK: - Trim & Playhead

  private func trimBorderOverlay(width: CGFloat, height: CGFloat, trimStart: Double, trimEnd: Double, borderColor: Color) -> some View {
    let startX = width * trimStart
    let endX = width * trimEnd
    let selectionWidth = endX - startX

    return ZStack(alignment: .leading) {
      Color.clear.frame(width: width, height: height)

      RoundedRectangle(cornerRadius: 10)
        .stroke(borderColor, lineWidth: 2)
        .frame(width: max(0, selectionWidth), height: height)
        .offset(x: startX)
    }
    .allowsHitTesting(false)
  }

  private func trimHandleOverlay(
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

  // MARK: - Playhead Overlay

  private var playheadOverlay: some View {
    GeometryReader { geo in
      let contentWidth = geo.size.width - sidebarWidth - 8
      let centerX = sidebarWidth + contentWidth * playheadFraction

      Rectangle()
        .fill(ReframedColors.controlAccentColor.opacity(0.5))
        .frame(width: 2, height: geo.size.height - rulerHeight)
        .position(x: centerX, y: rulerHeight + (geo.size.height - rulerHeight) / 2)
        .allowsHitTesting(false)

      RoundedRectangle(cornerRadius: 6)
        .fill(ReframedColors.controlAccentColor.opacity(0.9))
        .frame(width: 12, height: 28)
        .position(x: centerX, y: rulerHeight / 2)
        .gesture(
          DragGesture(minimumDistance: 0)
            .onChanged { value in
              let x = value.location.x - sidebarWidth
              let fraction = max(0, min(1, x / contentWidth))
              let time = CMTime(seconds: fraction * totalSeconds, preferredTimescale: 600)
              onScrub(time)
            }
        )
    }
  }
}
