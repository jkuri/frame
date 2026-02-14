import SwiftUI

extension PropertiesPanel {
  var backgroundSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      sectionHeader(icon: "paintbrush.fill", title: "Background")

      Picker("", selection: $backgroundMode) {
        ForEach(BackgroundMode.allCases, id: \.rawValue) { mode in
          Text(mode.label).tag(mode)
        }
      }
      .pickerStyle(.segmented)

      switch backgroundMode {
      case .none:
        EmptyView()
      case .gradient:
        gradientGrid
      case .color:
        solidColorPicker
      }
    }
  }

  var gradientGrid: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
      ForEach(GradientPresets.all) { preset in
        Button {
          selectedGradientId = preset.id
        } label: {
          Circle()
            .fill(
              LinearGradient(
                colors: preset.colors,
                startPoint: preset.startPoint,
                endPoint: preset.endPoint
              )
            )
            .frame(width: 36, height: 36)
            .overlay(
              Circle()
                .stroke(selectedGradientId == preset.id ? Color.blue : Color.clear, lineWidth: 2)
                .padding(1)
            )
        }
        .buttonStyle(.plain)
      }
    }
  }

  var solidColorPicker: some View {
    Button {
      showColorPopover.toggle()
    } label: {
      HStack(spacing: 6) {
        Circle()
          .fill(solidColorDisplay)
          .frame(width: 16, height: 16)
        Text(selectedColorId ?? "Blue")
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
    .popover(isPresented: $showColorPopover, arrowEdge: .trailing) {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          ForEach(TailwindColors.all) { preset in
            Button {
              selectedColorId = preset.id
              showColorPopover = false
            } label: {
              HStack(spacing: 10) {
                Circle()
                  .fill(preset.swiftUIColor)
                  .frame(width: 18, height: 18)
                Text(preset.name)
                  .font(.system(size: 13))
                  .foregroundStyle(ReframedColors.primaryText)
                Spacer()
                if selectedColorId == preset.id {
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

  var solidColorDisplay: Color {
    guard let id = selectedColorId, let preset = TailwindColors.all.first(where: { $0.id == id }) else {
      return TailwindColors.all[0].swiftUIColor
    }
    return preset.swiftUIColor
  }

  var paddingSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        sectionHeader(icon: "arrow.up.left.and.arrow.down.right", title: "Padding")
        Spacer()
        if editorState.padding > 0 {
          Button("Reset") {
            editorState.padding = 0
          }
          .font(.system(size: 11))
          .foregroundStyle(ReframedColors.dimLabel)
          .buttonStyle(.plain)
        }
      }

      HStack(spacing: 8) {
        Slider(value: $editorState.padding, in: 0...0.20, step: 0.01)
        Text("\(Int(editorState.padding * 100))%")
          .font(.system(size: 12, design: .monospaced))
          .foregroundStyle(ReframedColors.secondaryText)
          .frame(width: 36, alignment: .trailing)
      }
    }
  }

  var cornerRadiusSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        sectionHeader(icon: "rectangle.roundedtop", title: "Corner Radius")
        Spacer()
        if editorState.videoCornerRadius > 0 {
          Button("Reset") {
            editorState.videoCornerRadius = 0
          }
          .font(.system(size: 11))
          .foregroundStyle(ReframedColors.dimLabel)
          .buttonStyle(.plain)
        }
      }

      HStack(spacing: 8) {
        Slider(value: $editorState.videoCornerRadius, in: 0...40, step: 1)
        Text("\(Int(editorState.videoCornerRadius))px")
          .font(.system(size: 12, design: .monospaced))
          .foregroundStyle(ReframedColors.secondaryText)
          .frame(width: 36, alignment: .trailing)
      }
    }
  }
}
