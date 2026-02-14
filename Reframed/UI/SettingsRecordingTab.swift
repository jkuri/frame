import SwiftUI

extension SettingsView {
  var recordingContent: some View {
    Group {
      frameRateSection
      timerDelaySection
    }
  }

  var frameRateSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionLabel("Frame Rate")

      HStack {
        Text("FPS")
          .font(.system(size: 13))
          .foregroundStyle(ReframedColors.primaryText)
        Spacer()
        HStack(spacing: 4) {
          ForEach(fpsOptions, id: \.self) { option in
            Button {
              options?.fps = option
            } label: {
              Text("\(option)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ReframedColors.primaryText)
                .frame(width: 44, height: 28)
                .background(options?.fps == option ? ReframedColors.selectedActive : ReframedColors.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
          }
        }
      }
      .padding(.horizontal, 10)
    }
  }

  var timerDelaySection: some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionLabel("Timer Delay")

      HStack {
        Text("Countdown")
          .font(.system(size: 13))
          .foregroundStyle(ReframedColors.primaryText)
        Spacer()
        HStack(spacing: 4) {
          ForEach(TimerDelay.allCases, id: \.self) { delay in
            Button {
              options?.timerDelay = delay
            } label: {
              Text(delay.label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ReframedColors.primaryText)
                .padding(.horizontal, 10)
                .frame(height: 28)
                .background(options?.timerDelay == delay ? ReframedColors.selectedActive : ReframedColors.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
          }
        }
      }
      .padding(.horizontal, 10)
    }
  }
}
