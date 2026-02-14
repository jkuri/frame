import SwiftUI

extension SettingsView {
  var generalContent: some View {
    Group {
      appearanceSection
      projectFolderSection
      outputSection
      optionsSection
    }
  }

  var appearanceSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionLabel("Appearance")

      HStack(spacing: 4) {
        ForEach(["system", "light", "dark"], id: \.self) { mode in
          Button {
            appearance = mode
            ConfigService.shared.appearance = mode
            updateWindowBackgrounds()
          } label: {
            Text(mode.capitalized)
              .font(.system(size: 12, weight: .medium))
              .foregroundStyle(ReframedColors.primaryText)
              .padding(.horizontal, 14)
              .frame(height: 28)
              .background(appearance == mode ? ReframedColors.selectedActive : ReframedColors.fieldBackground)
              .clipShape(RoundedRectangle(cornerRadius: 6))
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  var projectFolderSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionLabel("Project Folder")
      HStack(spacing: 8) {
        Text(projectFolder)
          .font(.system(size: 12))
          .foregroundStyle(ReframedColors.primaryText)
          .lineLimit(1)
          .truncationMode(.middle)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 10)
          .padding(.vertical, 7)
          .background(ReframedColors.fieldBackground)
          .clipShape(RoundedRectangle(cornerRadius: 6))

        Button("Browse") {
          chooseProjectFolder()
        }
        .buttonStyle(SettingsButtonStyle())
      }
    }
  }

  var outputSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionLabel("Output Folder")
      HStack(spacing: 8) {
        Text(outputFolder)
          .font(.system(size: 12))
          .foregroundStyle(ReframedColors.primaryText)
          .lineLimit(1)
          .truncationMode(.middle)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 10)
          .padding(.vertical, 7)
          .background(ReframedColors.fieldBackground)
          .clipShape(RoundedRectangle(cornerRadius: 6))

        Button("Browse") {
          chooseOutputFolder()
        }
        .buttonStyle(SettingsButtonStyle())
      }
    }
  }

  var optionsSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionLabel("Options")

      settingsToggle(
        "Remember Last Selection",
        isOn: Binding(
          get: { options?.rememberLastSelection ?? false },
          set: { options?.rememberLastSelection = $0 }
        )
      )
    }
  }
}
