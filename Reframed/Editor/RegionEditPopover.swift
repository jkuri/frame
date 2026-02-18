import SwiftUI

struct RegionEditPopover: View {
  let region: ZoomRegion
  let duration: Double
  let onUpdate: (Int, Int, [ZoomKeyframe]) -> Void
  let onRemove: () -> Void

  @State private var originalKeyframes: [ZoomKeyframe]
  @State private var zoomLevel: Double
  @State private var easeIn: Double
  @State private var easeOut: Double

  @Environment(\.colorScheme) private var colorScheme

  init(
    region: ZoomRegion,
    originalKeyframes: [ZoomKeyframe],
    duration: Double,
    onUpdate: @escaping (Int, Int, [ZoomKeyframe]) -> Void,
    onRemove: @escaping () -> Void
  ) {
    self.region = region
    self.duration = duration
    self.onUpdate = onUpdate
    self.onRemove = onRemove
    _originalKeyframes = State(initialValue: originalKeyframes)
    _zoomLevel = State(initialValue: region.peakZoom)
    _easeIn = State(initialValue: region.zoomStartTime - region.startTime)
    _easeOut = State(initialValue: region.endTime - region.zoomEndTime)
  }

  private var origZoomStartTime: Double {
    originalKeyframes.first(where: { $0.zoomLevel > 1.0 })?.t ?? originalKeyframes.first?.t ?? 0
  }

  private var origZoomEndTime: Double {
    originalKeyframes.last(where: { $0.zoomLevel > 1.0 })?.t ?? originalKeyframes.last?.t ?? 0
  }

  private let popoverLabelWidth: CGFloat = 52

  var body: some View {
    let _ = colorScheme
    VStack(alignment: .leading, spacing: 0) {
      SectionHeader(title: "Zoom")

      SliderRow(
        label: "Level",
        labelWidth: popoverLabelWidth,
        value: $zoomLevel,
        range: 1.1...5.0,
        step: 0.1,
        formattedValue: String(format: "%.1fx", zoomLevel)
      )
      .padding(.horizontal, 12)
      .padding(.vertical, 4)

      Divider()
        .background(ReframedColors.divider)
        .padding(.vertical, 4)

      SectionHeader(title: "Transition")

      SliderRow(
        label: "Ease In",
        labelWidth: popoverLabelWidth,
        value: $easeIn,
        range: 0.05...2.0,
        step: 0.05,
        formattedValue: String(format: "%.2fs", easeIn),
        valueWidth: 42
      )
      .padding(.horizontal, 12)
      .padding(.vertical, 4)

      SliderRow(
        label: "Ease Out",
        labelWidth: popoverLabelWidth,
        value: $easeOut,
        range: 0.05...2.0,
        step: 0.05,
        formattedValue: String(format: "%.2fs", easeOut),
        valueWidth: 42
      )
      .padding(.horizontal, 12)
      .padding(.vertical, 4)

      Divider()
        .background(ReframedColors.divider)
        .padding(.vertical, 4)

      Button {
        onRemove()
      } label: {
        HStack(spacing: 8) {
          Image(systemName: "trash")
            .font(.system(size: 11))
            .frame(width: 14)
          Text("Remove")
            .font(.system(size: 13))
          Spacer()
        }
        .foregroundStyle(.red.opacity(0.8))
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
    .padding(.vertical, 8)
    .frame(width: 260)
    .popoverContainerStyle()
    .onChange(of: zoomLevel) { commitChanges() }
    .onChange(of: easeIn) { commitChanges() }
    .onChange(of: easeOut) { commitChanges() }
  }

  private func commitChanges() {
    guard originalKeyframes.count >= 2 else { return }

    let regionStart = originalKeyframes.first!.t
    let regionEnd = originalKeyframes.last!.t
    let regionSpan = regionEnd - regionStart
    guard regionSpan > 0 else { return }

    let maxEase = regionSpan - 0.02
    let clampedEaseIn = max(0.01, min(easeIn, maxEase))
    let clampedEaseOut = max(0.01, min(easeOut, max(0.01, maxEase - clampedEaseIn)))
    let holdStart = regionStart + clampedEaseIn
    let holdEnd = regionEnd - clampedEaseOut

    let firstZoomIdx = originalKeyframes.firstIndex(where: { $0.zoomLevel > 1.0 })
    let lastZoomIdx = originalKeyframes.lastIndex(where: { $0.zoomLevel > 1.0 })
    let origHoldSpan = origZoomEndTime - origZoomStartTime

    var newKfs = originalKeyframes
    for i in 0..<newKfs.count {
      if newKfs[i].zoomLevel > 1.0 {
        newKfs[i].zoomLevel = zoomLevel
        if i == firstZoomIdx {
          newKfs[i].t = holdStart
        } else if i == lastZoomIdx {
          newKfs[i].t = holdEnd
        } else if origHoldSpan > 0 {
          let frac = (originalKeyframes[i].t - origZoomStartTime) / origHoldSpan
          newKfs[i].t = holdStart + frac * (holdEnd - holdStart)
        }
      }
    }

    onUpdate(region.startIndex, region.count, newKfs)
  }
}
