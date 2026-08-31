import AppKit
import SwiftUI

final class SettingsController: NSObject, NSWindowDelegate {
    let model = SettingsModel()
    private var window: NSWindow!
    private var refreshTimer: Timer?

    override init() {
        super.init()
        let hosting = NSHostingView(rootView: SettingsView(model: model))
        window = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = Theme.backgroundNS
        window.isReleasedWhenClosed = false
        window.contentView = hosting
        window.setContentSize(hosting.fittingSize)
        window.delegate = self
    }

    func show() {
        model.refresh()
        window.center()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        // 権限の状態を開いている間だけポーリング（許可した瞬間に表示が変わる）
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.model.refresh()
        }
    }

    func windowWillClose(_ notification: Notification) {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func contentViewForSnapshot() -> NSView? { window.contentView }
}
