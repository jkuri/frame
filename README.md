<p align="center">
  <img width="128" height="128" src="https://github.com/user-attachments/assets/77f29f81-0d3c-41af-9e7f-dd67990ebc01" />
</p>

# frame

A lightweight macOS screen recording app that lives in your menu bar. Record your entire screen, a specific window, or a selected region — then edit and export with a built-in video editor.

## Download

Grab the latest `.dmg` from the [Releases](https://github.com/jkuri/frame/releases) page.

## Features

### Recording

- Menu bar interface with floating toolbar
- Record full screen, single window, or custom region
- Region selection with resizable drag handles
- System audio and microphone capture
- Webcam overlay (Picture-in-Picture) during recording
- Configurable countdown timer before recording
- Pause and resume recordings
- Configurable FPS (24, 30, 40, 50, 60)
- Light and dark mode support

### Video Editor

- Built-in editor opens automatically after recording
- Timeline with trim handles for precise start/end selection
- Background styles: solid color, gradient presets, or none
- Adjustable padding and video corner radius
- Webcam PiP positioning (corner presets or drag to reposition)
- Webcam PiP customizable size, corner radius, and border
- Live preview of all effects before exporting
- Multiple editor windows can be open simultaneously

### Export

- Export to MP4 or MOV format
- H.264 and H.265 (HEVC) codec options
- Configurable export FPS (24, 30, 40, 50, 60, or original)
- Resolution options: Original, 4K, 1080p, 720p

### Project Management

- `.frm` project bundles preserve source recordings and editor state
- Reopen and re-edit previous recordings
- Rename projects from the properties panel
- Configurable project and export output folders

## Requirements

- macOS 15.0 or later
- Screen Recording permission
- Microphone permission (optional, for mic capture)
- Camera permission (optional, for webcam overlay)

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
