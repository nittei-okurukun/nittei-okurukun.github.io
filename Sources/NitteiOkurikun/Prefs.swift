import AppKit

enum Prefs {
    private static let d = UserDefaults.standard

    struct HotKey {
        var keyCode: Int64
        var modifiers: NSEvent.ModifierFlags
        var display: String
    }

    static let defaultHotKey = HotKey(keyCode: 45, modifiers: [.control, .command], display: "⌃⌘N")

    static var hotKey: HotKey {
        get {
            guard let code = d.object(forKey: "hotKeyCode") as? Int,
                  let mods = d.object(forKey: "hotKeyMods") as? UInt,
                  let display = d.string(forKey: "hotKeyDisplay")
            else { return defaultHotKey }
            return HotKey(keyCode: Int64(code),
                          modifiers: NSEvent.ModifierFlags(rawValue: mods),
                          display: display)
        }
        set {
            d.set(Int(newValue.keyCode), forKey: "hotKeyCode")
            d.set(newValue.modifiers.rawValue, forKey: "hotKeyMods")
            d.set(newValue.display, forKey: "hotKeyDisplay")
        }
    }

    static var didOnboard: Bool {
        get { d.bool(forKey: "didOnboard") }
        set { d.set(newValue, forKey: "didOnboard") }
    }

    /// NSEvent から表示用文字列（例: ⌃⌘N）を作る
    static func displayString(keyCode: UInt16, modifiers: NSEvent.ModifierFlags,
                              characters: String?) -> String {
        var s = ""
        if modifiers.contains(.control) { s += "⌃" }
        if modifiers.contains(.option) { s += "⌥" }
        if modifiers.contains(.shift) { s += "⇧" }
        if modifiers.contains(.command) { s += "⌘" }
        let special: [UInt16: String] = [
            36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "Esc",
            123: "←", 124: "→", 125: "↓", 126: "↑",
        ]
        if let name = special[keyCode] {
            s += name
        } else if let ch = characters, !ch.isEmpty {
            s += ch.uppercased()
        } else {
            s += "?"
        }
        return s
    }
}
