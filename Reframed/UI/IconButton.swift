import SwiftUI

struct IconButton: View {
  let systemName: String
  var color: Color = ReframedColors.primaryText
  let action: () -> Void

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    let _ = colorScheme
    Button(action: action) {
      Image(systemName: systemName)
        .font(.system(size: 14))
        .frame(width: 28, height: 28)
    }
    .buttonStyle(.plain)
    .foregroundStyle(color)
  }
}
