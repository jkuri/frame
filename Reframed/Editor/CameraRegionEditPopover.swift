import SwiftUI

struct CameraRegionEditPopover: View {
  let regionType: CameraRegionType
  let onChangeType: (CameraRegionType) -> Void
  let onRemove: () -> Void

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    let _ = colorScheme
    VStack(alignment: .leading, spacing: 0) {
      SectionHeader(title: "Camera Region")

      VStack(alignment: .leading, spacing: 4) {
        Text("Type")
          .font(.system(size: 12))
          .foregroundStyle(ReframedColors.secondaryText)
        Picker(
          "",
          selection: Binding(
            get: { regionType },
            set: { onChangeType($0) }
          )
        ) {
          Text("Fullscreen").tag(CameraRegionType.fullscreen)
          Text("Hidden").tag(CameraRegionType.hidden)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
      }
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
    .frame(width: 200)
    .popoverContainerStyle()
  }
}
