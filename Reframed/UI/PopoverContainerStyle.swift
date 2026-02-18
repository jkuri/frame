import SwiftUI

struct PopoverContainerStyle: ViewModifier {
  @Environment(\.colorScheme) private var colorScheme

  func body(content: Content) -> some View {
    let _ = colorScheme
    content
      .background(ReframedColors.panelBackground)
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .strokeBorder(ReframedColors.subtleBorder, lineWidth: 0.5)
      )
  }
}

extension View {
  func popoverContainerStyle() -> some View {
    modifier(PopoverContainerStyle())
  }
}
