import SwiftUI

struct ModeButton: View {
  let icon: String
  let label: String
  let isSelected: Bool
  let action: () -> Void

  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      VStack(spacing: 3) {
        Image(systemName: icon)
          .font(.system(size: 18))
          .foregroundStyle(.white)
        Text(label)
          .font(.system(size: 10))
          .foregroundStyle(Color.white.opacity(0.6))
      }
      .frame(width: 56, height: 52)
      .background(
        isSelected ? Color.white.opacity(0.12) :
        isHovered ? Color.white.opacity(0.06) :
        Color.clear
      )
      .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    .buttonStyle(.plain)
    .onHover { isHovered = $0 }
  }
}
