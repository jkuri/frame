import SwiftUI

struct StartRecordingButton: View {
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        Image(systemName: "record.circle")
          .font(.system(size: 15, weight: .semibold))
        Text("Start recording")
          .font(.system(size: 15, weight: .semibold))
      }
      .foregroundStyle(.white)
      .padding(.horizontal, 24)
      .frame(height: 48)
      .background(Color(nsColor: .controlAccentColor))
      .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    .buttonStyle(.plain)
  }
}
