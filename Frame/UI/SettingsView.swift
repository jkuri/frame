import SwiftUI

struct SettingsView: View {
  var body: some View {
    VStack {
      Text("Settings")
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(.primary)
        .padding(.top, 20)

      Spacer()

      Text("Coming soon")
        .font(.system(size: 13))
        .foregroundStyle(.secondary)

      Spacer()
    }
    .frame(width: 480, height: 360)
  }
}
