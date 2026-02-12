# Reframed

A powerful macOS screen recorder with built-in video editor. Capture your screen, windows, regions, or iOS devices over USB with webcam overlay — then trim, style, and export.

## Download

Grab the latest `.dmg` from the [Releases](https://github.com/jkuri/reframed/releases) page.

## Features

### Recording

- Menu bar interface with floating capture toolbar
- Record full screen, single window, or custom region
- Record iOS devices (iPhone/iPad) connected via USB
- Region selection with resizable drag handles
- System audio and microphone capture
- Webcam overlay (Picture-in-Picture) during recording, including device mode
- Mouse click visualization with configurable color and size
- Configurable countdown timer before recording
- Pause and resume recordings
- Configurable FPS (24, 30, 40, 50, 60)
- Sound effects for recording actions (start, stop, pause, resume)
- Remember last selection area between recordings
- Light and dark mode support with appearance settings

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

### Settings

- Tabbed settings panel (General, Recording, Devices)
- Configurable output and project folders
- Camera maximum resolution selection (720p, 1080p, 4K)
- Mouse click monitor with color picker and size slider
- Appearance preference (System, Light, Dark)

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
