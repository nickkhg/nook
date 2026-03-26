import AppKit
import KeyboardShortcuts

/// Handles two types of keyboard shortcuts:
/// 1. Global shortcuts via KeyboardShortcuts package (configured per-item)
/// 2. Number keys 1-9 via local NSEvent monitor (when panel is open)
@MainActor
final class HotkeyMonitor {
    private var allItems: [ShortcutItem] = []
    private var registeredNames: [KeyboardShortcuts.Name] = []
    private var localMonitor: Any?

    var isPanelVisible: () -> Bool = { false }
    var onPanelItemLaunched: ((ShortcutItem) -> Void)?

    func updateBindings(from items: [ShortcutItem]) {
        // Clear old global shortcut registrations
        for name in registeredNames {
            KeyboardShortcuts.disable(name)
            KeyboardShortcuts.reset(name)
        }
        registeredNames.removeAll()
        allItems = items

        // Register global shortcuts from config
        for item in items {
            guard let shortcutStr = item.shortcut else { continue }
            guard let shortcut = parseShortcut(shortcutStr) else {
                NSLog("Nook: Invalid shortcut format: %@", shortcutStr)
                continue
            }

            let name = KeyboardShortcuts.Name("nook-item-\(item.id.uuidString)")
            KeyboardShortcuts.setShortcut(shortcut, for: name)

            let capturedItem = item
            KeyboardShortcuts.onKeyUp(for: name) {
                NSLog("Nook: Global shortcut fired for '%@'", capturedItem.label)
                ShortcutLauncher.launch(capturedItem)
            }

            registeredNames.append(name)
            NSLog("Nook: Registered global shortcut '%@' for '%@'", shortcutStr, item.label)
        }
    }

    func start() {
        // Local monitor for number keys when the panel is open
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let handled = MainActor.assumeIsolated {
                self?.handleNumberKey(event) ?? false
            }
            return handled ? nil : event
        }
    }

    func stop() {
        for name in registeredNames {
            KeyboardShortcuts.disable(name)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        localMonitor = nil
    }

    // MARK: - Number keys (local, when panel is open)

    private func handleNumberKey(_ event: NSEvent) -> Bool {
        guard isPanelVisible() else { return false }

        // Only bare number keys, no modifiers
        guard !event.modifierFlags.contains(.command),
              !event.modifierFlags.contains(.control),
              !event.modifierFlags.contains(.option) else { return false }

        let numberKeys: [UInt16: Int] = [
            18: 0, 19: 1, 20: 2, 21: 3, 23: 4,
            22: 5, 26: 6, 28: 7, 25: 8,
        ]

        guard let index = numberKeys[event.keyCode],
              index < allItems.count else { return false }

        let item = allItems[index]
        ShortcutLauncher.launch(item)
        onPanelItemLaunched?(item)
        return true
    }

    // MARK: - Shortcut parsing

    private func parseShortcut(_ string: String) -> KeyboardShortcuts.Shortcut? {
        let parts = string.lowercased().split(separator: "+").map(String.init)
        guard let keyPart = parts.last?.trimmingCharacters(in: .whitespaces) else { return nil }

        var mods: NSEvent.ModifierFlags = []
        for part in parts.dropLast() {
            switch part.trimmingCharacters(in: .whitespaces) {
            case "fn", "function": mods.insert(.function)
            case "ctrl", "control": mods.insert(.control)
            case "cmd", "command": mods.insert(.command)
            case "opt", "option", "alt": mods.insert(.option)
            case "shift": mods.insert(.shift)
            default: return nil
            }
        }

        guard let key = keyForString(keyPart) else { return nil }
        return KeyboardShortcuts.Shortcut(key, modifiers: mods)
    }

    private func keyForString(_ key: String) -> KeyboardShortcuts.Key? {
        if key.count == 1, let char = key.first {
            if char.isLetter, let code = letterCodes[char] {
                return KeyboardShortcuts.Key(rawValue: code)
            }
            if char.isNumber, let code = numberCodes[char] {
                return KeyboardShortcuts.Key(rawValue: code)
            }
        }
        if let code = specialCodes[key] {
            return KeyboardShortcuts.Key(rawValue: code)
        }
        return nil
    }

    private let letterCodes: [Character: Int] = [
        "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7,
        "c": 8, "v": 9, "b": 11, "q": 12, "w": 13, "e": 14, "r": 15,
        "y": 16, "t": 17, "u": 32, "i": 34, "p": 35, "l": 37, "j": 38,
        "k": 40, "n": 45, "m": 46, "o": 31,
    ]

    private let numberCodes: [Character: Int] = [
        "1": 18, "2": 19, "3": 20, "4": 21, "5": 23, "6": 22,
        "7": 26, "8": 28, "9": 25, "0": 29,
    ]

    private let specialCodes: [String: Int] = [
        "space": 49, "return": 36, "tab": 48, "escape": 53,
        "delete": 51, "up": 126, "down": 125, "left": 123, "right": 124,
        "f1": 122, "f2": 120, "f3": 99, "f4": 118, "f5": 96,
        "f6": 97, "f7": 98, "f8": 100, "f9": 101, "f10": 109,
        "f11": 103, "f12": 111,
    ]
}
