import SwiftUI

struct StartRecordingButton: View {
  let delay: Int
  var onCountdownStart: (() -> Void)?
  var onCancel: (() -> Void)?
  let action: () -> Void

  @State private var remaining: Int?
  @State private var countdownTask: Task<Void, Never>?

  var body: some View {
    Button {
      if remaining != nil {
        countdownTask?.cancel()
        countdownTask = nil
        remaining = nil
        onCancel?()
        return
      }
      onCountdownStart?()
      guard delay > 0 else {
        action()
        return
      }
      startCountdown()
    } label: {
      HStack(spacing: 6) {
        if let remaining {
          Image(systemName: "timer")
            .font(.system(size: 15, weight: .semibold))
          Text("Recording in \(remaining)...")
            .font(.system(size: 15, weight: .semibold))
        } else {
          Image(systemName: "record.circle")
            .font(.system(size: 15, weight: .semibold))
          Text("Start recording")
            .font(.system(size: 15, weight: .semibold))
        }
      }
      .foregroundStyle(.white)
      .padding(.horizontal, 24)
      .frame(height: 48)
      .background(Color(nsColor: .controlAccentColor))
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .contentTransition(.numericText())
      .animation(.default, value: remaining)
    }
    .buttonStyle(.plain)
    .onDisappear {
      countdownTask?.cancel()
      countdownTask = nil
    }
  }

  private func startCountdown() {
    remaining = delay
    countdownTask = Task { @MainActor in
      var count = delay
      while count > 0 {
        try? await Task.sleep(for: .seconds(1))
        if Task.isCancelled { return }
        count -= 1
        if count > 0 {
          remaining = count
        }
      }
      remaining = nil
      countdownTask = nil
      action()
    }
  }
}
