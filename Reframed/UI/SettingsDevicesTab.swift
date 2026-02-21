import SwiftUI

extension SettingsView {
  var devicesContent: some View {
    Group {
      audioSection
      cameraSectionView
    }
  }

  var microphoneLabel: String {
    guard let id = options?.selectedMicrophone?.id else { return "None" }
    return availableMicrophones.first { $0.id == id }?.name ?? "None"
  }

  var audioSection: some View {
    VStack(alignment: .leading, spacing: Layout.itemSpacing) {
      sectionLabel("Audio")

      settingsToggle(
        "Capture System Audio",
        isOn: Binding(
          get: { options?.captureSystemAudio ?? false },
          set: { options?.captureSystemAudio = $0 }
        )
      )

      HStack {
        Text("Microphone")
          .font(.system(size: 13))
          .foregroundStyle(ReframedColors.primaryText)
        Spacer()
        SelectButton(label: microphoneLabel, fixedWidth: 260) {
          VStack(alignment: .leading, spacing: 0) {
            CheckmarkRow(title: "None", isSelected: options?.selectedMicrophone == nil) {
              options?.selectedMicrophone = nil
            }
            ForEach(availableMicrophones) { mic in
              CheckmarkRow(title: mic.name, isSelected: options?.selectedMicrophone?.id == mic.id) {
                options?.selectedMicrophone = mic
              }
            }
          }
          .padding(.vertical, 8)
          .frame(width: 320)
        }
      }
      .padding(.horizontal, 10)
    }
  }

  var cameraLabelText: String {
    guard let id = options?.selectedCamera?.id else { return "None" }
    return availableCameras.first { $0.id == id }?.name ?? "None"
  }

  var cameraSectionView: some View {
    VStack(alignment: .leading, spacing: Layout.itemSpacing) {
      sectionLabel("Camera")

      HStack {
        Text("Camera Device")
          .font(.system(size: 13))
          .foregroundStyle(ReframedColors.primaryText)
        Spacer()
        SelectButton(label: cameraLabelText, fixedWidth: 260) {
          VStack(alignment: .leading, spacing: 0) {
            CheckmarkRow(title: "None", isSelected: options?.selectedCamera == nil) {
              options?.selectedCamera = nil
            }
            ForEach(availableCameras) { cam in
              CheckmarkRow(title: cam.name, isSelected: options?.selectedCamera?.id == cam.id) {
                options?.selectedCamera = cam
              }
            }
          }
          .padding(.vertical, 8)
          .frame(width: 320)
        }
      }
      .padding(.horizontal, 10)

      HStack {
        Text("Maximum Resolution")
          .font(.system(size: 13))
          .foregroundStyle(ReframedColors.primaryText)
        Spacer()
        SegmentPicker(
          items: ["720p", "1080p", "4K"],
          label: { $0 },
          isSelected: { cameraMaximumResolution == $0 },
          onSelect: {
            cameraMaximumResolution = $0
            ConfigService.shared.cameraMaximumResolution = $0
          }
        )
      }
      .padding(.horizontal, 10)
    }
  }
}
