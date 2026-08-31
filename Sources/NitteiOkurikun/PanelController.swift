import AppKit
import SwiftUI

final class KeyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override func cancelOperation(_ sender: Any?) {
        orderOut(nil)   // Esc で閉じる
    }
}

final class PanelController: NSObject, NSWindowDelegate {
    let model = ScheduleModel()
    private var panel: KeyPanel!
    var onCommit: ((String) -> Void)?

    override init() {
        super.init()
        let content = ContentView(model: model) { [weak self] text in
            self?.onCommit?(text)
        }
        let hosting = NSHostingView(rootView: content)
        panel = KeyPanel(
            contentRect: .zero,
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.backgroundColor = Theme.backgroundNS
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.contentView = hosting
        panel.setContentSize(hosting.fittingSize)
        panel.delegate = self
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
    }

    func show() {
        model.prepareForOpen()
        panel.center()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func close() {
        panel.orderOut(nil)
    }

    var isVisible: Bool { panel.isVisible }

    func contentViewForSnapshot() -> NSView? { panel.contentView }

    /// すでに開いているパネルを前面に戻す
    func bringToFront() {
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }
}
