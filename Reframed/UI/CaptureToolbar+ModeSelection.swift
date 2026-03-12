import SwiftUI

extension CaptureToolbar {
  var modeSelectionContent: some View {
    HoverEffectScope {
      HStack(spacing: 0) {
        Button {
          session.hideToolbar()
        } label: {
          VStack(spacing: 3) {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: Layout.toolbarIconSize))
              .foregroundStyle(ReframedColors.primaryText)
            Text("Close")
              .font(.system(size: FontSize.xxs, weight: .semibold))
              .foregroundStyle(ReframedColors.primaryText)
          }
          .frame(width: Layout.toolbarHeight + 4, height: Layout.toolbarHeight)
          .contentShape(Rectangle())
        }
        .buttonStyle(PlainCustomButtonStyle())
        .hoverEffect(id: "close")

        ToolbarDivider()

        HStack(spacing: 2) {
          ModeButton(
            icon: "display",
            label: "Display",
            isSelected: session.captureMode == .entireScreen
          ) {
            session.selectMode(.entireScreen)
          }
          .hoverEffect(id: "mode.display")

          ModeButton(
            icon: "macwindow",
            label: "Window",
            isSelected: session.captureMode == .selectedWindow
          ) {
            session.selectMode(.selectedWindow)
          }
          .hoverEffect(id: "mode.window")

          ModeButton(
            icon: "rectangle.dashed",
            label: "Area",
            isSelected: session.captureMode == .selectedArea
          ) {
            session.selectMode(.selectedArea)
          }
          .hoverEffect(id: "mode.area")

          ModeButton(
            icon: "iphone",
            label: "Device",
            isSelected: session.captureMode == .device
          ) {
            showDevicePopover.toggle()
          }
          .hoverEffect(id: "mode.device")
          .popover(isPresented: $showDevicePopover, arrowEdge: .bottom) {
            DevicePopover { deviceId in
              showDevicePopover = false
              session.selectMode(.device)
              session.startDeviceRecordingWith(deviceId: deviceId)
            }
            .presentationBackground(ReframedColors.backgroundPopover)
          }
        }

        ToolbarDivider()

        HStack(spacing: 2) {
          ToolbarToggleButton(
            icon: "web.camera",
            activeIcon: "web.camera.fill",
            label: "Camera",
            isOn: session.isCameraOn,
            isAvailable: true,
            tooltip: "Camera",
            action: {
              if session.options.selectedCamera != nil {
                session.toggleCamera()
              } else {
                showCameraPicker.toggle()
              }
            }
          )
          .hoverEffect(id: "toggle.camera")
          .popover(isPresented: $showCameraPicker, arrowEdge: .bottom) {
            DevicePickerPopover(
              title: "Select Camera",
              emptyMessage: "No cameras found",
              devices: session.options.availableCameras.map {
                DevicePickerItem(id: $0.id, name: $0.name)
              },
              selectedId: session.options.selectedCamera?.id,
              onSelect: { device in
                session.options.selectedCamera = CaptureDevice(id: device.id, name: device.name)
                showCameraPicker = false
                session.toggleCamera()
              }
            )
            .presentationBackground(ReframedColors.backgroundPopover)
          }

          ToolbarToggleButton(
            icon: "mic",
            activeIcon: "mic.fill",
            label: "Mic",
            isOn: session.isMicrophoneOn,
            isAvailable: true,
            tooltip: "Microphone",
            action: {
              if session.options.selectedMicrophone != nil {
                session.toggleMicrophone()
              } else {
                showMicPicker.toggle()
              }
            }
          )
          .hoverEffect(id: "toggle.mic")
          .popover(isPresented: $showMicPicker, arrowEdge: .bottom) {
            DevicePickerPopover(
              title: "Select Microphone",
              emptyMessage: "No microphones found",
              devices: session.options.availableMicrophones.map {
                DevicePickerItem(id: $0.id, name: $0.name)
              },
              selectedId: session.options.selectedMicrophone?.id,
              onSelect: { device in
                session.options.selectedMicrophone = AudioDevice(id: device.id, name: device.name)
                showMicPicker = false
                session.toggleMicrophone()
              }
            )
            .presentationBackground(ReframedColors.backgroundPopover)
          }

          ToolbarToggleButton(
            icon: "speaker.wave.2",
            activeIcon: "speaker.wave.2.fill",
            label: "Audio",
            isOn: session.options.captureSystemAudio,
            isAvailable: true,
            tooltip: "System Audio",
            action: { session.options.captureSystemAudio.toggle() }
          )
          .hoverEffect(id: "toggle.audio")
        }

        ToolbarDivider()

        Button {
          showOptions.toggle()
        } label: {
          VStack(spacing: 3) {
            Image(systemName: "list.bullet")
              .font(.system(size: Layout.toolbarIconSize))
              .foregroundStyle(ReframedColors.primaryText)
            Text("Options")
              .font(.system(size: FontSize.xxs, weight: .semibold))
              .foregroundStyle(ReframedColors.primaryText)
          }
          .frame(width: Layout.toolbarHeight + 4, height: Layout.toolbarHeight)
          .contentShape(Rectangle())
        }
        .buttonStyle(PlainCustomButtonStyle())
        .hoverEffect(id: "btn.options")
        .popover(isPresented: $showOptions, arrowEdge: .bottom) {
          OptionsPopover(options: session.options)
            .presentationBackground(ReframedColors.backgroundPopover)
        }

        ToolbarDivider()

        Button {
          showSettings.toggle()
        } label: {
          VStack(spacing: 3) {
            Image(systemName: "gearshape")
              .font(.system(size: Layout.toolbarIconSize))
              .foregroundStyle(ReframedColors.primaryText)
            Text("Settings")
              .font(.system(size: FontSize.xxs, weight: .semibold))
              .foregroundStyle(ReframedColors.primaryText)
          }
          .frame(width: Layout.toolbarHeight + 4, height: Layout.toolbarHeight)
          .contentShape(Rectangle())
        }
        .buttonStyle(PlainCustomButtonStyle())
        .hoverEffect(id: "btn.settings")
        .popover(isPresented: $showSettings, arrowEdge: .bottom) {
          SettingsView(options: session.options)
            .presentationBackground(ReframedColors.backgroundPopover)
        }
      }
    }
  }
}
