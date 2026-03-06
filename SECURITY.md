# Security policy

## Supported versions

Only the latest release gets security fixes. Check [Releases](https://github.com/jkuri/Reframed/releases) for the current version.

| Version | Supported |
| ------- | --------- |
| Latest  | Yes       |
| Older   | No        |

## Reporting a vulnerability

If you find a security issue, please don't open a public issue. Instead, email [jkuri88@gmail.com](mailto:jkuri88@gmail.com) with:

- A description of the vulnerability
- Steps to reproduce it
- Any relevant logs or screenshots

I'll acknowledge your report within 48 hours and work with you on a fix before any public disclosure.

## Scope

Reframed runs without the App Sandbox (ScreenCaptureKit requires it) and requests several system permissions:

- Screen Recording
- Accessibility (cursor and keystroke capture)
- Microphone (optional)
- Camera (optional)

Security issues related to how the app handles these permissions, stores user data, or processes recordings are all in scope.

## Disclosure

Once a fix is ready, I'll publish a new release with a note in the changelog. If you reported the issue, you'll get credit unless you prefer otherwise.
