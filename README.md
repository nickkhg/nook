# Nook

A macOS menu bar app that shows a launchpad-style panel of quick-launch shortcuts when the cursor enters the notch area.

## Features

- **Notch-triggered**: panel appears when your cursor enters the notch (or top-center on non-notched Macs)
- **Quick launch**: apps, URLs, files/folders, shell scripts, terminal commands, and Shortcuts.app automations
- **Terminal integration**: open commands in a new tab of your preferred terminal (Terminal, iTerm2, Warp, Ghostty, Kitty, Alacritty)
- **Global hotkeys**: assign a keyboard shortcut to any item to launch it from anywhere
- **Number keys**: press 1–9 while the panel is open to launch items by position
- **Task mode**: shell scripts with `runAsTask` run as toggleable background processes
- **Custom icons**: override any item's icon with an SF Symbol name
- **Liquid Glass**: native macOS 26 glass effects
- **Non-intrusive**: floating panel doesn't steal focus from the active app
- **JSON config**: edit `~/Library/Application Support/nook/config.json` with full schema validation
- **Menu bar only**: no Dock icon, minimal footprint

## Requirements

- macOS 26+
- Swift 6.2+
- **Accessibility** permission (for terminal keystroke automation)
- **Automation** permission (for Apple Events communication with terminal apps)

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
    { "label": "Safari", "type": { "kind": "app", "bundleIdentifier": "com.apple.Safari" }, "shortcut": "fn+s" },
    { "label": "GitHub", "type": { "kind": "url", "urlString": "https://github.com" } },
    { "label": "Downloads", "type": { "kind": "file", "path": "~/Downloads" }, "iconOverride": "folder.fill" },
    { "label": "Cleanup", "type": { "kind": "shellScript", "path": "~/.scripts/cleanup.sh" } },
    { "label": "Dev Server", "type": { "kind": "shellScript", "path": "~/scripts/server.sh", "runAsTask": true } },
    { "label": "Morning", "type": { "kind": "shortcutsApp", "shortcutName": "Morning Routine" } },
    { "label": "SSH Prod", "type": { "kind": "terminal", "command": "ssh prod-server", "app": "iTerm2" } }
  ]
}
```

### Item fields

| Field | Required | Description |
|-------|----------|-------------|
| `label` | yes | Display label shown below the icon |
| `type` | yes | Shortcut type object (see below) |
| `iconOverride` | no | SF Symbol name to use instead of the auto-detected icon |
| `shortcut` | no | Global hotkey string (e.g. `"fn+g"`, `"ctrl+shift+1"`, `"cmd+opt+t"`) |

### Shortcut types

| Kind | Required fields | Description |
|------|----------------|-------------|
| `app` | `bundleIdentifier` | Launch a macOS app |
| `url` | `urlString` | Open a URL in the default browser |
| `file` | `path` | Open a file or folder (supports `~`) |
| `shellScript` | `path` | Run a shell script. Optional: `arguments`, `runAsTask` |
| `shortcutsApp` | `shortcutName` | Run a Shortcuts.app automation |
| `terminal` | `command` | Run a command in a new terminal tab. Optional: `directory`, `app` |

Supported terminal apps for the `terminal` type: Terminal, iTerm2, Warp, Ghostty, Kitty, Alacritty (defaults to Terminal).

### Task mode

Set `"runAsTask": true` on a `shellScript` item to run it as a tracked background process. The tile shows a green indicator while running. Tap again to kill the process.

### Keyboard shortcuts

- **Global hotkeys**: Add a `"shortcut"` field to any item to launch it from anywhere. Modifiers: `fn`, `ctrl`, `cmd`, `opt`, `shift`. Example: `"shortcut": "fn+g"`.
- **Number keys**: While the panel is open, press `1`–`9` to launch items by grid position.

## Building

Open `nook.xcodeproj` in Xcode and build, or:

```sh
xcodebuild -project nook.xcodeproj -scheme nook -configuration Release build
```
