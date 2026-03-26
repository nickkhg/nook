import AppKit

/// Parses shortcut strings like "fn+g", "ctrl+shift+1", "cmd+opt+t"
/// and matches them against NSEvent key events.
struct HotkeySpec: Equatable {
    let keyCode: UInt16
    let modifiers: NSEvent.ModifierFlags

    init?(from string: String) {
        let parts = string.lowercased().split(separator: "+").map(String.init)
        guard let keyPart = parts.last else { return nil }

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

        guard let code = Self.keyCodeForString(keyPart.trimmingCharacters(in: .whitespaces)) else {
            return nil
        }

        self.keyCode = code
        self.modifiers = mods
    }

    func matches(_ event: NSEvent) -> Bool {
        guard event.keyCode == keyCode else { return false }

        let relevantMods: [(NSEvent.ModifierFlags, Bool)] = [
            (.function, modifiers.contains(.function)),
            (.control, modifiers.contains(.control)),
            (.command, modifiers.contains(.command)),
            (.option, modifiers.contains(.option)),
            (.shift, modifiers.contains(.shift)),
        ]

        for (flag, required) in relevantMods {
            let present = event.modifierFlags.contains(flag)
            if required != present { return false }
        }

        return true
    }

    private static func keyCodeForString(_ key: String) -> UInt16? {
        if key.count == 1, let char = key.first, char.isLetter {
            return letterKeyCodes[char]
        }
        if key.count == 1, let char = key.first, char.isNumber {
            return numberKeyCodes[char]
        }
        return specialKeyCodes[key]
    }

    private static let letterKeyCodes: [Character: UInt16] = [
        "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7,
        "c": 8, "v": 9, "b": 11, "q": 12, "w": 13, "e": 14, "r": 15,
        "y": 16, "t": 17, "u": 32, "i": 34, "p": 35, "l": 37, "j": 38,
        "k": 40, "n": 45, "m": 46, "o": 31,
    ]

    private static let numberKeyCodes: [Character: UInt16] = [
        "1": 18, "2": 19, "3": 20, "4": 21, "5": 23, "6": 22,
        "7": 26, "8": 28, "9": 25, "0": 29,
    ]

    private static let specialKeyCodes: [String: UInt16] = [
        "space": 49, "return": 36, "enter": 36, "tab": 48,
        "escape": 53, "esc": 53, "delete": 51, "backspace": 51,
        "up": 126, "down": 125, "left": 123, "right": 124,
        "f1": 122, "f2": 120, "f3": 99, "f4": 118, "f5": 96,
        "f6": 97, "f7": 98, "f8": 100, "f9": 101, "f10": 109,
        "f11": 103, "f12": 111,
    ]
}

/// Global keyboard monitor for configured hotkeys and panel number keys.
@MainActor
final class HotkeyMonitor {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var bindings: [(spec: HotkeySpec, item: ShortcutItem)] = []
    private var allItems: [ShortcutItem] = []

    /// Set this to check if the panel is open for number key support.
    var isPanelVisible: () -> Bool = { false }
    /// Called when a number key launches an item from the panel.
    var onPanelItemLaunched: ((ShortcutItem) -> Void)?

    func updateBindings(from items: [ShortcutItem]) {
        allItems = items
        bindings = items.compactMap { item in
            guard let shortcutStr = item.shortcut,
                  let spec = HotkeySpec(from: shortcutStr) else { return nil }
            return (spec, item)
        }
    }

    func start() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            MainActor.assumeIsolated { () -> Void in
                self?.handleKeyEvent(event)
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let handled = MainActor.assumeIsolated {
                self?.handleKeyEvent(event) ?? false
            }
            return handled ? nil : event
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }

    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        // Check configured shortcuts first
        for (spec, item) in bindings {
            if spec.matches(event) {
                ShortcutLauncher.launch(item)
                return true
            }
        }

        // Number keys 1-9 when panel is open
        if isPanelVisible() {
            let numberKeys: [UInt16: Int] = [
                18: 0, 19: 1, 20: 2, 21: 3, 23: 4,
                22: 5, 26: 6, 28: 7, 25: 8,
            ]
            if let index = numberKeys[event.keyCode],
               // Make sure no modifiers are held (just bare number key)
               !event.modifierFlags.contains(.command),
               !event.modifierFlags.contains(.control),
               !event.modifierFlags.contains(.option),
               index < allItems.count {
                let item = allItems[index]
                ShortcutLauncher.launch(item)
                onPanelItemLaunched?(item)
                return true
            }
        }

        return false
    }
}
