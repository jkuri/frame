import AVFoundation
import SwiftUI

extension TimelineView {
  func trackSidebar(label: String, icon: String) -> some View {
    VStack(spacing: 4) {
      Image(systemName: icon)
        .font(.system(size: FontSize.sm))
      Text(label)
        .font(.system(size: FontSize.xxs, weight: .semibold))
    }
    .foregroundStyle(ReframedColors.primaryText)
  }

  func screenTrackContent(width: CGFloat) -> some View {
    let h = trackHeight
    let regions = editorState.videoRegions

    return ZStack(alignment: .leading) {
      ForEach(regions) { region in
        videoRegionView(
          region: region,
          width: width,
          height: h
        )
      }
    }
    .frame(width: width, height: h)
    .clipped()
    .coordinateSpace(name: "videoRegion")
    .contentShape(Rectangle())
    .onTapGesture(count: 2) { location in
      let time = (location.x / width) * totalSeconds
      editorState.addVideoRegion(atTime: time)
    }
  }

  func videoTrackBackground(
    width: CGFloat,
    height: CGFloat,
    isWebcam: Bool = false,
    trimStart: Double,
    trimEnd: Double
  ) -> some View {
    return ZStack(alignment: .leading) {
      Color.clear

      RoundedRectangle(cornerRadius: Track.borderRadius)
        .fill(Track.background)
        .frame(width: max(0, width * (trimEnd - trimStart)), height: height)
        .offset(x: width * trimStart)
    }
    .frame(width: width, height: height)
  }
}
