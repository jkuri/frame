import SwiftUI

struct ToggleRow: View {
  let label: String
  @Binding var isOn: Bool

  var body: some View {
    HStack {
      Text(label)
        .font(.system(size: 12))
        .foregroundStyle(ReframedColors.primaryText)
      Spacer()
      CustomToggle(isOn: $isOn)
    }
  }
}
