import SwiftUI

struct CameraRegionEditPopover: View {
  let regionType: CameraRegionType
  let onChangeType: (CameraRegionType) -> Void
  let onRemove: () -> Void

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    let _ = colorScheme
    VStack(alignment: .leading, spacing: Layout.regionPopoverSpacing) {
      SectionHeader(title: "Camera Region")

      FullWidthSegmentPicker(
        items: CameraRegionType.allCases,
        label: { $0.label },
        selection: Binding(
          get: { regionType },
          set: { onChangeType($0) }
        )
      )
      .padding(.horizontal, 12)
      .padding(.vertical, 4)

      Button {
        onRemove()
      } label: {
        HStack(spacing: 5) {
          Image(systemName: "trash")
            .font(.system(size: 12, weight: .semibold))
          Text("Remove")
            .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        .background(Color.red.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 7))
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
    }
    .padding(.vertical, 8)
    .frame(width: Layout.regionPopoverWidth)
    .popoverContainerStyle()
  }
}
