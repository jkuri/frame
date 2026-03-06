# Contributing to Reframed

Thanks for wanting to help out. Here's what you need to know.

## Getting started

You'll need macOS 15+ and Xcode with Swift 6. Clone the repo and run:

```bash
make build
```

That's it. Dependencies are managed through SPM and resolve automatically.

To build and launch in one step:

```bash
make dev
```

## Making changes

1. Fork the repo and create a branch from `main`.
2. Make your changes.
3. Run `make format` to format your code.
4. Run `make build` and fix any warnings or errors.
5. Open a pull request against `main`.

## Code style

- No code comments. No inline comments, no doc comments. The code should speak for itself.
- Reuse existing UI components from `Reframed/UI/` before creating new ones. The project has its own button styles (`OutlineButtonStyle`, `PrimaryButtonStyle`, `SecondaryButtonStyle`) -- never use `.borderless`, `.plain`, or other stock SwiftUI button styles.
- Reuse utility functions from `Reframed/Utilities/` when they exist.
- If a view goes past 200 lines, split it into separate files using Swift extensions.
- Fix root causes. No band-aid fixes or temporary workarounds.

## Project structure

The codebase is organized by concern:

- `App/` -- entry point, permissions, window management
- `Recording/` -- capture pipeline and writers
- `Editor/` -- timeline, properties, preview
- `Compositor/` -- video composition and export
- `State/` -- app state, config, services
- `UI/` -- reusable components, toolbar, settings
- `Utilities/` -- extensions and helpers

See `CLAUDE.md` for a more detailed breakdown.

## Concurrency

Everything uses Swift 6 strict concurrency. `SessionState` lives on `@MainActor`. Recording coordinators and writers are actors. If you're passing data across isolation boundaries, look at how existing code handles it before inventing a new pattern.

## Reporting bugs

Open an issue with:

- What you did
- What happened
- What you expected
- macOS version and any relevant system info

Screenshots or screen recordings help a lot, especially for UI issues.

## Feature requests

Open an issue describing what you want and why. Keep it concrete -- "I want X so I can do Y" is more useful than a vague suggestion.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
