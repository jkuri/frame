import CoreMedia
import SwiftUI

enum EditorTab: String, CaseIterable, Identifiable {
  case general, video, camera, cursor, zoom

  var id: String { rawValue }

  var label: String {
    switch self {
    case .general: "General"
    case .video: "Video"
    case .camera: "Camera"
    case .cursor: "Cursor"
    case .zoom: "Zoom"
    }
  }

  var icon: String {
    switch self {
    case .general: "slider.horizontal.3"
    case .video: "play.rectangle"
    case .camera: "web.camera"
    case .cursor: "cursorarrow"
    case .zoom: "plus.magnifyingglass"
    }
  }
}

struct EditorView: View {
  @Bindable var editorState: EditorState
  @State private var systemWaveformGenerator = AudioWaveformGenerator()
  @State private var micWaveformGenerator = AudioWaveformGenerator()
  @State private var selectedTab: EditorTab = .general
  @Environment(\.colorScheme) private var colorScheme

  let onSave: (URL) -> Void
  let onCancel: () -> Void
  let onDelete: () -> Void

  var body: some View {
    let _ = colorScheme
    VStack(spacing: 0) {
      EditorTopBar(
        editorState: editorState,
        onOpenFolder: { editorState.openProjectFolder() },
        onDelete: { editorState.showDeleteConfirmation = true }
      )
      .padding(.bottom, 4)

      HStack(spacing: 6) {
        mainContent
          .background(ReframedColors.panelBackground)
          .clipShape(RoundedRectangle(cornerRadius: 8))
        editorSidebar
          .background(ReframedColors.panelBackground)
          .clipShape(RoundedRectangle(cornerRadius: 8))
        PropertiesPanel(editorState: editorState, selectedTab: selectedTab)
          .background(ReframedColors.panelBackground)
          .clipShape(RoundedRectangle(cornerRadius: 8))
      }
      .padding(.horizontal, 12)
      .frame(maxHeight: .infinity)

      timeline
        .fixedSize(horizontal: false, vertical: true)
        .background(ReframedColors.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }
    .background(ReframedColors.selectedBackground.opacity(0.55))
    .task {
      await editorState.setup()
      let sysURL = editorState.result.systemAudioURL
      let micURL = editorState.result.microphoneAudioURL
      async let sysTask: Void = {
        if let url = sysURL { await systemWaveformGenerator.generate(from: url) }
      }()
      async let micTask: Void = {
        if let url = micURL { await micWaveformGenerator.generate(from: url) }
      }()
      _ = await (sysTask, micTask)
    }
    .sheet(isPresented: $editorState.showExportSheet) {
      ExportSheet(isPresented: $editorState.showExportSheet, sourceFPS: editorState.result.fps) { settings in
        handleExport(settings: settings)
      }
    }
    .alert("Delete Recording?", isPresented: $editorState.showDeleteConfirmation) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        editorState.deleteRecording()
        onDelete()
      }
    } message: {
      Text("This will permanently delete the source recording files.")
    }
    .alert(
      editorState.exportResultIsError ? "Export Failed" : "Export Successful",
      isPresented: $editorState.showExportResult
    ) {
      Button("OK") {}
      if !editorState.exportResultIsError {
        Button("Show in Finder") {
          editorState.openExportedFile()
        }
      }
    } message: {
      Text(editorState.exportResultMessage)
    }
  }

  private var editorSidebar: some View {
    VStack(spacing: 0) {
      HoverEffectScope {
        VStack(spacing: 2) {
          ForEach(EditorTab.allCases) { tab in
            Button {
              selectedTab = tab
            } label: {
              VStack(spacing: 3) {
                Image(systemName: tab.icon)
                  .font(.system(size: 16))
                  .foregroundStyle(selectedTab == tab ? ReframedColors.primaryText : ReframedColors.secondaryText)
                Text(tab.label)
                  .font(.system(size: 10))
                  .foregroundStyle(selectedTab == tab ? ReframedColors.secondaryText : ReframedColors.dimLabel)
              }
              .frame(width: 56, height: 48)
              .background(
                selectedTab == tab ? ReframedColors.selectedBackground : Color.clear,
                in: RoundedRectangle(cornerRadius: 8)
              )
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverEffect(id: "tab.\(tab.rawValue)")
          }
        }
      }
      Spacer()
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 4)
  }

  private var mainContent: some View {
    VStack(spacing: 0) {
      videoPreview
        .frame(maxHeight: .infinity)
      EditorBottomBar(editorState: editorState)
    }
  }

  private var videoPreview: some View {
    let screenSize = editorState.result.screenSize
    let hasEffects =
      editorState.backgroundStyle != .none || editorState.padding > 0
      || editorState.videoCornerRadius > 0
    let canvasAspect: CGFloat = {
      let canvas = editorState.canvasSize(for: screenSize)
      return canvas.width / max(canvas.height, 1)
    }()

    return GeometryReader { geo in
      ZStack {
        if hasEffects {
          backgroundView
        }

        VideoPreviewView(
          screenPlayer: editorState.playerController.screenPlayer,
          webcamPlayer: editorState.playerController.webcamPlayer,
          pipLayout: $editorState.pipLayout,
          webcamSize: editorState.result.webcamSize,
          screenSize: screenSize,
          canvasSize: editorState.canvasSize(for: screenSize),
          padding: editorState.padding,
          videoCornerRadius: editorState.videoCornerRadius,
          pipCornerRadius: editorState.pipCornerRadius,
          pipBorderWidth: editorState.pipBorderWidth,
          cursorMetadataProvider: editorState.cursorMetadataProvider,
          showCursor: editorState.showCursor,
          cursorStyle: editorState.cursorStyle,
          cursorSize: editorState.cursorSize,
          cursorSmoothing: editorState.cursorSmoothing,
          showClickHighlights: editorState.showClickHighlights,
          clickHighlightColor: editorState.clickHighlightColor.cgColor,
          clickHighlightSize: editorState.clickHighlightSize,
          zoomFollowCursor: editorState.zoomFollowCursor,
          currentTime: CMTimeGetSeconds(editorState.currentTime),
          zoomTimeline: editorState.zoomTimeline
        )
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .aspectRatio(hasEffects ? canvasAspect : screenSize.width / max(screenSize.height, 1), contentMode: .fit)
      .clipShape(RoundedRectangle(cornerRadius: hasEffects ? 0 : previewCornerRadius(screenSize: screenSize, viewSize: geo.size)))
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
  }

  @ViewBuilder
  private var backgroundView: some View {
    switch editorState.backgroundStyle {
    case .none:
      Color.clear
    case .gradient(let id):
      if let preset = GradientPresets.preset(for: id) {
        LinearGradient(
          colors: preset.colors,
          startPoint: preset.startPoint,
          endPoint: preset.endPoint
        )
      } else {
        Color.clear
      }
    case .solidColor(let codableColor):
      Color(cgColor: codableColor.cgColor)
    }
  }

  private var timeline: some View {
    TimelineView(
      editorState: editorState,
      systemAudioSamples: systemWaveformGenerator.samples,
      micAudioSamples: micWaveformGenerator.samples,
      onScrub: { time in
        editorState.pause()
        editorState.seek(to: time)
      }
    )
  }

  private func previewCornerRadius(screenSize: CGSize, viewSize: CGSize) -> CGFloat {
    let nativeRadius: CGFloat = 10
    let scale = min(viewSize.width / max(screenSize.width, 1), viewSize.height / max(screenSize.height, 1))
    return nativeRadius * scale
  }

  private func handleExport(settings: ExportSettings) {
    Task {
      do {
        let url = try await editorState.export(settings: settings)
        editorState.exportResultMessage = "Saved to \(url.lastPathComponent)"
        editorState.exportResultIsError = false
      } catch {
        editorState.exportResultMessage = error.localizedDescription
        editorState.exportResultIsError = true
      }
      editorState.showExportResult = true
    }
  }
}
