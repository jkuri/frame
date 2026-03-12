import SwiftUI

struct ZoomKeyframeEditor: View {
  let keyframes: [ZoomKeyframe]
  let duration: Double
  let width: CGFloat
  let height: CGFloat
  let scrollOffset: CGFloat
  let timelineZoom: CGFloat
  let onAddKeyframe: (Double) -> Void
  let onRemoveRegion: (Int, Int) -> Void
  let onUpdateRegion: (Int, Int, [ZoomKeyframe]) -> Void
  @Environment(\.colorScheme) private var colorScheme

  @State var dragOffset: CGFloat = 0
  @State var dragType: RegionDragType?
  @State var dragRegionStartIndex: Int?
  @State var popoverRegionIndex: Int?

  var regions: [ZoomRegion] {
    groupZoomRegions(from: keyframes)
  }

  var body: some View {
    let _ = colorScheme
    ZStack(alignment: .leading) {
      RoundedRectangle(cornerRadius: Track.borderRadius)
        .fill(ReframedColors.backgroundCard)
        .frame(width: width, height: height)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { location in
          let fraction = max(0, min(1, location.x / width))
          let time = fraction * duration
          let hitRegion = regions.first { region in
            let startX = (region.startTime / duration) * width
            let endX = (region.endTime / duration) * width
            return location.x >= startX && location.x <= endX
          }
          if hitRegion == nil {
            onAddKeyframe(time)
          }
        }

      if regions.isEmpty {
        let viewportWidth = width / timelineZoom
        let visibleCenterX = scrollOffset + viewportWidth / 2
        Text("Double-click to add zoom region")
          .font(.system(size: FontSize.xs))
          .foregroundStyle(ReframedColors.secondaryText)
          .fixedSize()
          .position(x: visibleCenterX, y: height / 2)
          .allowsHitTesting(false)
      }

      ForEach(Array(regions.enumerated()), id: \.offset) { _, region in
        regionView(for: region)
      }
    }
    .frame(width: width, height: height)
    .clipShape(RoundedRectangle(cornerRadius: Track.borderRadius))
    .coordinateSpace(name: "zoomEditor")
  }
}
