import SwiftUI

extension PropertiesPanel {
  var backgroundSection: some View {
    VStack(alignment: .leading, spacing: Layout.itemSpacing) {
      SectionHeader(icon: "paintbrush.fill", title: "Background")

      SegmentPicker(
        items: BackgroundMode.allCases,
        label: { $0.label },
        selection: $backgroundMode
      )

      switch backgroundMode {
      case .color:
        solidColorGrid
      case .gradient:
        gradientGrid
      case .image:
        imageBackgroundSection
      }
    }
  }

  private var swatchColumns: [GridItem] {
    Array(repeating: GridItem(.flexible(), spacing: 6), count: 8)
  }

  var gradientGrid: some View {
    LazyVGrid(columns: swatchColumns, spacing: 6) {
      ForEach(GradientPresets.all) { preset in
        SwatchButton(
          fill: LinearGradient(
            colors: preset.colors,
            startPoint: preset.startPoint,
            endPoint: preset.endPoint
          ),
          isSelected: selectedGradientId == preset.id
        ) {
          selectedGradientId = preset.id
        }
      }
    }
  }

  var imageBackgroundSection: some View {
    VStack(alignment: .leading, spacing: Layout.itemSpacing) {
      ImageDropSection(
        image: editorState.backgroundImage,
        onPick: { pickBackgroundImage() },
        onDrop: { url in
          editorState.setBackgroundImage(from: url)
          if case .image(let f) = editorState.backgroundStyle {
            backgroundImageFilename = f
          }
        }
      )
      if editorState.backgroundImage != nil {
        VStack(alignment: .leading, spacing: Layout.itemSpacing) {
          SectionHeader(icon: "arrow.up.left.and.arrow.down.right", title: "Fill Mode")

          SegmentPicker(
            items: BackgroundImageFillMode.allCases,
            label: { $0.label },
            selection: $editorState.backgroundImageFillMode
          )
        }
      }
    }
  }

  var solidColorGrid: some View {
    LazyVGrid(columns: swatchColumns, spacing: 6) {
      ForEach(TailwindColors.all) { preset in
        SwatchButton(
          fill: preset.swiftUIColor,
          isSelected: selectedColorId == preset.id
        ) {
          selectedColorId = preset.id
        }
      }
    }
  }

  var paddingSection: some View {
    VStack(alignment: .leading, spacing: Layout.itemSpacing) {
      HStack {
        SectionHeader(icon: "arrow.up.left.and.arrow.down.right", title: "Padding")
        Spacer()
        if editorState.padding > 0 {
          Button("Reset") {
            editorState.padding = 0
          }
          .font(.system(size: FontSize.xs))
          .foregroundStyle(ReframedColors.secondaryText)
          .buttonStyle(SecondaryButtonStyle())
        }
      }

      SliderRow(
        value: $editorState.padding,
        range: 0...0.50,
        step: 0.01,
        formattedValue: "\(Int(editorState.padding * 100))%"
      )
    }
  }

  var cornerRadiusSection: some View {
    VStack(alignment: .leading, spacing: Layout.itemSpacing) {
      HStack {
        SectionHeader(icon: "rectangle.roundedtop", title: "Corner Radius")
        Spacer()
        if editorState.videoCornerRadius > 0 {
          Button("Reset") {
            editorState.videoCornerRadius = 0
          }
          .font(.system(size: FontSize.xs))
          .foregroundStyle(ReframedColors.secondaryText)
          .buttonStyle(SecondaryButtonStyle())
        }
      }

      SliderRow(
        value: $editorState.videoCornerRadius,
        range: 0...50,
        formattedValue: "\(Int(editorState.videoCornerRadius))%"
      )
    }
  }

  var videoShadowSection: some View {
    VStack(alignment: .leading, spacing: Layout.itemSpacing) {
      HStack {
        SectionHeader(icon: "shadow", title: "Shadow")
        Spacer()
        if editorState.videoShadow > 0 {
          Button("Reset") {
            editorState.videoShadow = 0
          }
          .font(.system(size: FontSize.xs))
          .foregroundStyle(ReframedColors.secondaryText)
          .buttonStyle(SecondaryButtonStyle())
        }
      }

      SliderRow(
        value: $editorState.videoShadow,
        range: 0...100,
        formattedValue: "\(Int(editorState.videoShadow))"
      )
    }
  }
}
