import SwiftUI

struct SelectionControlsView: View {
  let session: SessionState
  @State private var x: Int = 0
  @State private var y: Int = 0
  @State private var w: Int = 0
  @State private var h: Int = 0
  @State private var isEditing = false

  private let fieldBg = Color.white.opacity(0.08)
  private let labelColor = Color.white.opacity(0.4)

  var body: some View {
    VStack(spacing: 0) {
      VStack(spacing: 10) {
        HStack(spacing: 0) {
          Text("Size")
            .font(.system(size: 12))
            .foregroundStyle(labelColor)
            .frame(width: 56, alignment: .leading)

          numericField(value: $w)
          Text("\u{00D7}")
            .font(.system(size: 12))
            .foregroundStyle(labelColor)
            .frame(width: 20)
          numericField(value: $h)
          Text("px")
            .font(.system(size: 11))
            .foregroundStyle(labelColor)
            .frame(width: 24, alignment: .trailing)
        }

        HStack(spacing: 0) {
          Text("Position")
            .font(.system(size: 12))
            .foregroundStyle(labelColor)
            .frame(width: 56, alignment: .leading)

          numericField(value: $x)
          Spacer().frame(width: 20)
          numericField(value: $y)
          Text("px")
            .font(.system(size: 11))
            .foregroundStyle(labelColor)
            .frame(width: 24, alignment: .trailing)
        }
      }
      .padding(.horizontal, 30)
      .padding(.vertical, 30)
      .background(Color(white: 0.1))
      .clipShape(RoundedRectangle(cornerRadius: 6))

      Button(action: { session.overlayView?.confirmSelection() }) {
        HStack(spacing: 6) {
          Image(systemName: "record.circle")
            .font(.system(size: 15, weight: .semibold))
          Text("Start recording")
            .font(.system(size: 15, weight: .semibold))
        }
        .foregroundStyle(.white)
        .frame(width: 200)
        .frame(height: 48)
        .background(Color(nsColor: .controlAccentColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
      }
      .buttonStyle(.plain)
      .padding(.top, 8)
    }
    .frame(width: 260)
    .onReceive(NotificationCenter.default.publisher(for: .selectionRectChanged)) { notification in
      guard !isEditing, let rect = notification.object as? NSValue else { return }
      let r = rect.rectValue
      x = Int(r.origin.x)
      y = Int(r.origin.y)
      w = Int(r.width)
      h = Int(r.height)
    }
  }

  private func numericField(value: Binding<Int>) -> some View {
    TextField("", value: value, format: .number)
      .textFieldStyle(.plain)
      .font(.system(size: 14, design: .monospaced))
      .foregroundStyle(.white)
      .multilineTextAlignment(.center)
      .frame(width: 70, height: 40)
      .background(fieldBg)
      .clipShape(RoundedRectangle(cornerRadius: 6))
      .onSubmit {
        isEditing = false
        applyValues()
      }
      .onChange(of: value.wrappedValue) {
        if isEditing {
          applyValues()
        }
      }
      .onTapGesture {
        isEditing = true
      }
  }

  private func applyValues() {
    let rect = CGRect(
      x: CGFloat(x),
      y: CGFloat(y),
      width: CGFloat(max(w, 10)),
      height: CGFloat(max(h, 10))
    )
    session.updateOverlaySelection(rect)
  }
}

extension Notification.Name {
  static let selectionRectChanged = Notification.Name("selectionRectChanged")
}
