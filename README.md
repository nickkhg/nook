# Nook

A macOS menu bar app that shows a launchpad-style panel of quick-launch shortcuts when the cursor enters the notch area.

## Features

- **Notch-triggered**: panel appears when your cursor enters the notch (or top-center on non-notched Macs)
- **Quick launch**: apps, URLs, files/folders, shell scripts, and Shortcuts.app automations
- **Task mode**: shell scripts with `runAsTask` run as toggleable background processes
- **Liquid Glass**: native macOS 26 glass effects
- **Non-intrusive**: floating panel doesn't steal focus from the active app
- **JSON config**: edit `~/Library/Application Support/nook/config.json` with full schema validation
- **Menu bar only**: no Dock icon, minimal footprint

## Requirements

- macOS 26+
- Swift 6.2+

## Configuration

Shortcuts are configured via JSON at `~/Library/Application Support/nook/config.json`. A default config is created on first launch.

Add the `$schema` property for autocomplete and validation in VS Code:

```json
{
  "$schema": "https://github.com/nickkhg/nook/raw/main/nook-config.schema.json",
  "columns": 4,
  "triggerHeight": 5,
  "panelWidth": 340,
  "items": [
    { "id": "...", "label": "Safari", "type": { "kind": "app", "bundleIdentifier": "com.apple.Safari" } },
    { "id": "...", "label": "GitHub", "type": { "kind": "url", "urlString": "https://github.com" } },
    { "id": "...", "label": "Downloads", "type": { "kind": "file", "path": "~/Downloads" } },
    { "id": "...", "label": "Cleanup", "type": { "kind": "shellScript", "path": "~/.scripts/cleanup.sh" } },
    { "id": "...", "label": "Dev Server", "type": { "kind": "shellScript", "path": "~/scripts/server.sh", "runAsTask": true } },
    { "id": "...", "label": "Morning", "type": { "kind": "shortcutsApp", "shortcutName": "Morning Routine" } }
  ]
}
```

### Shortcut types

| Kind | Required fields | Description |
|------|----------------|-------------|
| `app` | `bundleIdentifier` | Launch a macOS app |
| `url` | `urlString` | Open a URL in the default browser |
| `file` | `path` | Open a file or folder (supports `~`) |
| `shellScript` | `path` | Run a shell script. Optional: `arguments`, `runAsTask` |
| `shortcutsApp` | `shortcutName` | Run a Shortcuts.app automation |

### Task mode

Set `"runAsTask": true` on a `shellScript` item to run it as a tracked background process. The tile shows a green indicator while running. Tap again to kill the process.

## Building

Open `nook.xcodeproj` in Xcode and build, or:

```sh
xcodebuild -project nook.xcodeproj -scheme nook -configuration Release build
```
