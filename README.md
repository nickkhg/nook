# Nook

A macOS menu bar app that shows a launchpad-style panel of quick-launch shortcuts when the cursor enters the notch area.

## Features

- **Notch-triggered**: panel appears when your cursor enters the notch (or top-center on non-notched Macs)
- **Quick launch**: apps, URLs, files/folders, shell scripts, and Shortcuts.app automations
- **Non-intrusive**: floating panel doesn't steal focus from the active app
- **JSON config**: edit `~/Library/Application Support/nook/config.json` to customize shortcuts
- **Menu bar only**: no Dock icon, minimal footprint

## Requirements

- macOS 26+
- Swift 6.2+

## Configuration

Shortcuts are configured via JSON at `~/Library/Application Support/nook/config.json`. A default config is created on first launch.

```json
{
  "columns": 4,
  "triggerHeight": 5,
  "panelWidth": 340,
  "items": [
    { "id": "...", "label": "Safari", "type": { "kind": "app", "bundleIdentifier": "com.apple.Safari" } },
    { "id": "...", "label": "GitHub", "type": { "kind": "url", "urlString": "https://github.com" } },
    { "id": "...", "label": "Downloads", "type": { "kind": "file", "path": "~/Downloads" } },
    { "id": "...", "label": "Cleanup", "type": { "kind": "shellScript", "path": "~/.scripts/cleanup.sh" } },
    { "id": "...", "label": "Morning", "type": { "kind": "shortcutsApp", "shortcutName": "Morning Routine" } }
  ]
}
```

## Building

Open `nook.xcodeproj` in Xcode and build, or:

```sh
xcodebuild -project nook.xcodeproj -scheme nook -configuration Release build
```
