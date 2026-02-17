import SwiftUI

struct FullWidthSegmentPicker<Item: Hashable & Identifiable>: View {
  let items: [Item]
  let label: (Item) -> String
  @Binding var selection: Item
  @Environment(\.colorScheme) var colorScheme

  var body: some View {
    let _ = colorScheme
    HStack(spacing: 4) {
      ForEach(items) { item in
        let isSelected = selection == item
        Button {
          selection = item
        } label: {
          Text(label(item))
            .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
            .foregroundStyle(isSelected ? ReframedColors.primaryText : ReframedColors.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
              isSelected ? ReframedColors.selectedBackground : ReframedColors.fieldBackground,
              in: RoundedRectangle(cornerRadius: 6)
            )
        }
        .buttonStyle(.plain)
      }
    }
  }
}
