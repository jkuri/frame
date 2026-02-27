import CoreMedia
import SwiftUI

struct CaptionOverlayView: View {
  let text: String
  let position: CaptionPosition
  let fontSize: CGFloat
  let fontWeight: CaptionFontWeight
  let textColor: CodableColor
  let backgroundColor: CodableColor
  let backgroundOpacity: CGFloat
  let showBackground: Bool

  private var swiftUIFontWeight: Font.Weight {
    switch fontWeight {
    case .regular: .regular
    case .medium: .medium
    case .semibold: .semibold
    case .bold: .bold
    }
  }

  var body: some View {
    GeometryReader { geo in
      let scaledFontSize = fontSize * (geo.size.width / 1920.0)

      VStack {
        if position == .bottom || position == .center {
          Spacer()
        }

        Text(text)
          .font(.system(size: scaledFontSize, weight: swiftUIFontWeight))
          .foregroundStyle(Color(cgColor: textColor.cgColor))
          .multilineTextAlignment(.center)
          .lineLimit(2)
          .padding(.horizontal, scaledFontSize * 0.4)
          .padding(.vertical, scaledFontSize * 0.2)
          .background {
            if showBackground {
              RoundedRectangle(cornerRadius: scaledFontSize * 0.2)
                .fill(Color(cgColor: backgroundColor.cgColor).opacity(backgroundOpacity))
            }
          }
          .frame(maxWidth: geo.size.width * 0.9)

        if position == .top || position == .center {
          Spacer()
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, geo.size.height * 0.05)
    }
    .allowsHitTesting(false)
  }
}
