import SwiftUI

extension PropertiesPanel {
  var cursorStyleGrid: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 5), spacing: 4) {
      ForEach(CursorStyle.allCases, id: \.rawValue) { style in
        let isSelected = editorState.cursorStyle == style
        Button {
          editorState.cursorStyle = style
        } label: {
          VStack(spacing: 3) {
            Image(nsImage: CursorRenderer.previewImage(for: style, size: 42))
              .frame(width: 42, height: 42)
              .background(ReframedColors.fieldBackground)
              .clipShape(RoundedRectangle(cornerRadius: 5))
              .overlay(
                RoundedRectangle(cornerRadius: 5)
                  .stroke(isSelected ? ReframedColors.controlAccentColor : Color.clear, lineWidth: 2)
              )
            Text(style.label)
              .font(.system(size: 8, weight: isSelected ? .semibold : .regular))
              .foregroundStyle(isSelected ? ReframedColors.primaryText : ReframedColors.secondaryText)
              .lineLimit(1)
          }
        }
        .buttonStyle(.plain)
      }
    }
  }

  var cursorSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      sectionHeader(icon: "cursorarrow", title: "Cursor")

      toggleRow("Show Cursor", isOn: $editorState.showCursor)

      if editorState.showCursor {
        cursorStyleGrid

        HStack(spacing: 8) {
          Text("Size")
            .font(.system(size: 12))
            .foregroundStyle(ReframedColors.secondaryText)
            .frame(width: cursorLabelWidth, alignment: .leading)
          Slider(value: $editorState.cursorSize, in: 16...64, step: 2)
          Text("\(Int(editorState.cursorSize))px")
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(ReframedColors.secondaryText)
            .frame(width: 36, alignment: .trailing)
        }

        clickHighlightsSubsection
      }
    }
  }

  var clickHighlightsSubsection: some View {
    VStack(alignment: .leading, spacing: 14) {
      sectionHeader(icon: "cursorarrow.click.2", title: "Click Highlights")

      toggleRow("Show Highlights", isOn: $editorState.showClickHighlights)

      if editorState.showClickHighlights {
        HStack(spacing: 8) {
          Text("Color")
            .font(.system(size: 12))
            .foregroundStyle(ReframedColors.secondaryText)
            .frame(width: cursorLabelWidth, alignment: .leading)
          clickColorPickerButton
        }

        HStack(spacing: 8) {
          Text("Size")
            .font(.system(size: 12))
            .foregroundStyle(ReframedColors.secondaryText)
            .frame(width: cursorLabelWidth, alignment: .leading)
          Slider(value: $editorState.clickHighlightSize, in: 16...80, step: 2)
          Text("\(Int(editorState.clickHighlightSize))px")
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(ReframedColors.secondaryText)
            .frame(width: 36, alignment: .trailing)
        }
      }
    }
  }

  var clickColorPickerButton: some View {
    let currentName = TailwindColors.all.first { $0.color == editorState.clickHighlightColor }?.name ?? "Blue"
    return Button {
      showClickColorPopover.toggle()
    } label: {
      HStack(spacing: 6) {
        Circle()
          .fill(Color(cgColor: editorState.clickHighlightColor.cgColor))
          .frame(width: 16, height: 16)
        Text(currentName)
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(ReframedColors.primaryText)
          .lineLimit(1)
        Spacer()
        Image(systemName: "chevron.up.chevron.down")
          .font(.system(size: 9, weight: .semibold))
          .foregroundStyle(ReframedColors.dimLabel)
      }
      .padding(.horizontal, 10)
      .frame(height: 30)
      .background(ReframedColors.fieldBackground)
      .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    .buttonStyle(.plain)
    .popover(isPresented: $showClickColorPopover, arrowEdge: .trailing) {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          ForEach(TailwindColors.all) { preset in
            Button {
              editorState.clickHighlightColor = preset.color
              showClickColorPopover = false
            } label: {
              HStack(spacing: 10) {
                Circle()
                  .fill(preset.swiftUIColor)
                  .frame(width: 18, height: 18)
                Text(preset.name)
                  .font(.system(size: 13))
                  .foregroundStyle(ReframedColors.primaryText)
                Spacer()
                if editorState.clickHighlightColor == preset.color {
                  Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ReframedColors.primaryText)
                }
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 5)
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.vertical, 8)
      }
      .frame(width: 200)
      .frame(maxHeight: 320)
    }
  }

  func toggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
    HStack {
      Text(label)
        .font(.system(size: 12))
        .foregroundStyle(ReframedColors.primaryText)
      Spacer()
      Toggle("", isOn: isOn)
        .toggleStyle(.switch)
        .controlSize(.mini)
        .labelsHidden()
    }
  }

  var zoomSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      sectionHeader(icon: "plus.magnifyingglass", title: "Zoom")

      toggleRow("Enable Zoom", isOn: $editorState.zoomEnabled)
        .onChange(of: editorState.zoomEnabled) { _, enabled in
          if !enabled {
            editorState.autoZoomEnabled = false
            editorState.zoomTimeline = nil
          }
        }

      if editorState.zoomEnabled {
        toggleRow("Follow Cursor", isOn: $editorState.zoomFollowCursor)

        toggleRow("Auto Zoom", isOn: $editorState.autoZoomEnabled)
          .onChange(of: editorState.autoZoomEnabled) { _, enabled in
            if enabled {
              editorState.generateAutoZoom()
            } else {
              editorState.clearAutoZoom()
            }
          }

        if editorState.autoZoomEnabled {
          HStack {
            Text("Level")
              .font(.system(size: 12))
              .foregroundStyle(ReframedColors.secondaryText)
              .frame(width: zoomLabelWidth, alignment: .leading)
            Slider(value: $editorState.zoomLevel, in: 1.5...5.0, step: 0.1)
            Text(String(format: "%.1fx", editorState.zoomLevel))
              .font(.system(size: 12, design: .monospaced))
              .foregroundStyle(ReframedColors.secondaryText)
              .frame(width: 40, alignment: .trailing)
          }
          .onChange(of: editorState.zoomLevel) { _, _ in
            editorState.generateAutoZoom()
          }

          HStack {
            Text("Speed")
              .font(.system(size: 12))
              .foregroundStyle(ReframedColors.secondaryText)
              .frame(width: zoomLabelWidth, alignment: .leading)
            Slider(value: $editorState.zoomTransitionSpeed, in: 0.1...2.0, step: 0.05)
            Text(String(format: "%.2fs", editorState.zoomTransitionSpeed))
              .font(.system(size: 12, design: .monospaced))
              .foregroundStyle(ReframedColors.secondaryText)
              .frame(width: 40, alignment: .trailing)
          }
          .onChange(of: editorState.zoomTransitionSpeed) { _, _ in
            editorState.generateAutoZoom()
          }

          HStack {
            Text("Hold")
              .font(.system(size: 12))
              .foregroundStyle(ReframedColors.secondaryText)
              .frame(width: zoomLabelWidth, alignment: .leading)
            Slider(value: $editorState.zoomDwellThreshold, in: 0.5...5.0, step: 0.1)
            Text(String(format: "%.1fs", editorState.zoomDwellThreshold))
              .font(.system(size: 12, design: .monospaced))
              .foregroundStyle(ReframedColors.secondaryText)
              .frame(width: 40, alignment: .trailing)
          }
          .onChange(of: editorState.zoomDwellThreshold) { _, _ in
            editorState.generateAutoZoom()
          }
        }
      }
    }
  }
}
