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
  let screenWidth: CGFloat

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
      let rawFontSize = fontSize * (geo.size.width / max(screenWidth, 1))
      let scaledFontSize = max(12, min(rawFontSize, geo.size.height * 0.08))

      VStack {
        if position == .bottom || position == .center {
          Spacer()
        }

        Text(text)
          .font(.system(size: scaledFontSize, weight: swiftUIFontWeight))
          .foregroundStyle(Color(cgColor: textColor.cgColor))
          .multilineTextAlignment(.center)
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
