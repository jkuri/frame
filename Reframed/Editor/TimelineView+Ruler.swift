import AVFoundation
import SwiftUI

extension TimelineView {
  func timeRuler(width: CGFloat) -> some View {
    Canvas { context, size in
      let duration = totalSeconds
      let interval = rulerInterval(for: duration)
      let minorInterval = interval / 5

      var t: Double = 0
      while t <= duration {
        let x = CGFloat(t / duration) * size.width
        let isMajor = isApproximatelyMultiple(t, of: interval)

        if isMajor {
          let tickPath = Path { p in
            p.move(to: CGPoint(x: x, y: size.height - 10))
            p.addLine(to: CGPoint(x: x, y: size.height))
          }
          context.stroke(tickPath, with: .color(ReframedColors.primaryText), lineWidth: 1)

          let label = formatRulerTime(t)
          let text = Text(label)
            .font(.system(size: FontSize.xs, design: .monospaced))
            .foregroundStyle(ReframedColors.primaryText)
          context.draw(context.resolve(text), at: CGPoint(x: x, y: size.height - 16), anchor: .bottom)
        } else {
          let tickPath = Path { p in
            p.move(to: CGPoint(x: x, y: size.height - 5))
            p.addLine(to: CGPoint(x: x, y: size.height))
          }
          context.stroke(tickPath, with: .color(ReframedColors.primaryText.opacity(0.5)), lineWidth: 0.5)
        }
        t += minorInterval
      }
    }
    .frame(width: width, height: 32)
    .background(ReframedColors.backgroundCard)
    .contentShape(Rectangle())
    .gesture(rulerScrubGesture(width: width))
  }

  private func rulerInterval(for duration: Double) -> Double {
    let effectiveDuration = duration / timelineZoom
    if effectiveDuration <= 5 { return 1 }
    if effectiveDuration <= 15 { return 2 }
    if effectiveDuration <= 30 { return 5 }
    if effectiveDuration <= 60 { return 10 }
    if effectiveDuration <= 180 { return 30 }
    if effectiveDuration <= 600 { return 60 }
    return 120
  }

  private func isApproximatelyMultiple(_ value: Double, of interval: Double) -> Bool {
    let remainder = value.truncatingRemainder(dividingBy: interval)
    return remainder < 0.001 || (interval - remainder) < 0.001
  }

  private func formatRulerTime(_ seconds: Double) -> String {
    let mins = Int(seconds) / 60
    let secs = Int(seconds) % 60
    if totalSeconds >= 60 {
      return String(format: "%d:%02d", mins, secs)
    }
    return String(format: "0:%02d", secs)
  }

  private func rulerScrubGesture(width: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        let fraction = max(0, min(1, value.location.x / width))
        let time = CMTime(seconds: fraction * totalSeconds, preferredTimescale: 600)
        onScrub(time)
      }
  }
}
