import SwiftUI

struct TailwindColorPicker: View {
  let displayColor: Color
  let displayName: String
  @Binding var isPresented: Bool
  let isSelected: (ColorPreset) -> Bool
  let onSelect: (ColorPreset) -> Void

  var body: some View {
    Button {
      isPresented.toggle()
    } label: {
      HStack(spacing: 6) {
        Circle()
          .fill(displayColor)
          .frame(width: 16, height: 16)
        Text(displayName)
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
    .popover(isPresented: $isPresented, arrowEdge: .trailing) {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          ForEach(TailwindColors.all) { preset in
            Button {
              onSelect(preset)
              isPresented = false
            } label: {
              HStack(spacing: 10) {
                Circle()
                  .fill(preset.swiftUIColor)
                  .frame(width: 18, height: 18)
                Text(preset.name)
                  .font(.system(size: 13))
                  .foregroundStyle(ReframedColors.primaryText)
                Spacer()
                if isSelected(preset) {
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
}
