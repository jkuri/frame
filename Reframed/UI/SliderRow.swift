import SwiftUI

struct SliderRow<V: BinaryFloatingPoint>: View where V.Stride: BinaryFloatingPoint {
  var label: String? = nil
  var labelWidth: CGFloat? = nil
  @Binding var value: V
  let range: ClosedRange<V>
  var step: V.Stride = 1
  var formattedValue: String? = nil
  var valueWidth: CGFloat = 36

  var body: some View {
    HStack(spacing: 8) {
      if let label {
        if let labelWidth {
          Text(label)
            .font(.system(size: 12))
            .foregroundStyle(ReframedColors.secondaryText)
            .frame(width: labelWidth, alignment: .leading)
        } else {
          Text(label)
            .font(.system(size: 12))
            .foregroundStyle(ReframedColors.secondaryText)
        }
      }
      Slider(value: $value, in: range, step: step)
      if let formattedValue {
        Text(formattedValue)
          .font(.system(size: 12, design: .monospaced))
          .foregroundStyle(ReframedColors.secondaryText)
          .frame(width: valueWidth, alignment: .trailing)
      }
    }
  }
}
