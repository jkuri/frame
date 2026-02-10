# Frame

A lightweight macOS screen recording app that lives in your menu bar. Record your entire screen, a specific window, or a selected region and export to MP4.

<p align="center">
  <img src="https://github.com/user-attachments/assets/6e297b87-d349-4bf8-abd0-4e55649dd60f" />
</p>

## Features

- Menu bar interface with floating toolbar
- Record full screen, single window, or custom region
- Region selection with resizable drag handles
- System audio and microphone capture
- Pause and resume recordings
- H.264 MP4 output
- Light and dark mode support
- Configurable FPS and resolution settings
- More to come...

## Requirements

- macOS 15.0 or later
- Screen Recording permission
- Microphone permission (optional, for mic capture)
- Accessibility permission (for cursor tracking and auto zoom)

## Build

```bash
# Debug build
make build

# Release build
make release

# Build and run
make dev

# Create DMG installer
make dmg

# Install to /Applications
make install
```

## License

MIT
