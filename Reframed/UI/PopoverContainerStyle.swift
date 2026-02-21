import SwiftUI

struct PopoverContainerStyle: ViewModifier {
  @Environment(\.colorScheme) private var colorScheme

  func body(content: Content) -> some View {
    let _ = colorScheme
    content
      .background(ReframedColors.background)
      .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
      .overlay(
        RoundedRectangle(cornerRadius: Radius.lg)
          .strokeBorder(ReframedColors.border, lineWidth: 0.5)
      )
  }
}

extension View {
  func popoverContainerStyle() -> some View {
    modifier(PopoverContainerStyle())
  }
}
