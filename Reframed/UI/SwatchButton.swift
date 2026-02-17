import SwiftUI

struct SwatchButton<S: ShapeStyle>: View {
  let fill: S
  let isSelected: Bool
  let action: () -> Void
  @Environment(\.colorScheme) var colorScheme

  var body: some View {
    let _ = colorScheme
    Button(action: action) {
      RoundedRectangle(cornerRadius: 8)
        .fill(fill)
        .aspectRatio(1.0, contentMode: .fit)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(ReframedColors.divider, lineWidth: 1)
        )
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            .padding(1)
        )
    }
    .buttonStyle(.plain)
  }
}
