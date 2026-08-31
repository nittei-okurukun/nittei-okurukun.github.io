import AppKit
import ApplicationServices

/// ⌃⌘N をグローバルに監視するイベントタップ。
/// テキスト入力欄にフォーカスがある時だけイベントを奪ってパネルを開き、
/// それ以外はそのままアプリへ流す。
final class HotKeyTap {
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    var onHotKey: (() -> Void)?

    private var hotKey = Prefs.hotKey

    func reloadHotKey() {
        hotKey = Prefs.hotKey
    }

    func start() {
        guard tap == nil else { return }
        attemptStart()
        // アクセシビリティ未許可だとタップを作れない。許可されるまで定期的に再試行する
        if tap == nil {
            Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] timer in
                guard let self else { timer.invalidate(); return }
                self.attemptStart()
                if self.tap != nil { timer.invalidate() }
            }
        }
    }

    private func attemptStart() {
        guard tap == nil else { return }
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let me = Unmanaged<HotKeyTap>.fromOpaque(refcon).takeUnretainedValue()
            return me.handle(type: type, event: event)
        }
        tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        guard let tap else { return }
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }
        guard type == .keyDown,
              event.getIntegerValueField(.keyboardEventKeycode) == hotKey.keyCode,
              matches(event.flags),
              !NSApp.isActive,
              Self.isTextInputFocused()
        else {
            return Unmanaged.passUnretained(event)
        }
        DispatchQueue.main.async { [weak self] in self?.onHotKey?() }
        return nil // イベントを消費（元アプリには渡さない）
    }

    /// 設定されたホットキーの修飾キーと過不足なく一致するか
    private func matches(_ flags: CGEventFlags) -> Bool {
        var required = CGEventFlags()
        var forbidden: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate, .maskShift]
        let pairs: [(NSEvent.ModifierFlags, CGEventFlags)] = [
            (.command, .maskCommand), (.control, .maskControl),
            (.option, .maskAlternate), (.shift, .maskShift),
        ]
        for (ns, cg) in pairs where hotKey.modifiers.contains(ns) {
            required.insert(cg)
            forbidden.remove(cg)
        }
        return flags.contains(required) && flags.intersection(forbidden).isEmpty
    }

    /// フォーカス中の UI 要素がテキスト入力欄かどうか
    private static func isTextInputFocused() -> Bool {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            systemWide, kAXFocusedUIElementAttribute as CFString, &focusedRef) == .success,
            let focusedRef,
            CFGetTypeID(focusedRef) == AXUIElementGetTypeID()
        else { return false }
        let element = focusedRef as! AXUIElement

        var roleRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef) == .success,
           let role = roleRef as? String {
            let textRoles = ["AXTextField", "AXTextArea", "AXComboBox", "AXSearchField"]
            if textRoles.contains(role) { return true }
        }
        // Web の contenteditable などロールが揺れるケース: 選択テキスト範囲を持てば入力欄とみなす
        var rangeRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(
            element, kAXSelectedTextRangeAttribute as CFString, &rangeRef) == .success,
            rangeRef != nil {
            return true
        }
        return false
    }
}

enum Paste {
    /// 前面アプリへ ⌘V を送る
    static func sendCmdV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyV: CGKeyCode = 9
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: keyV, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: keyV, keyDown: false)
        else { return }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}
