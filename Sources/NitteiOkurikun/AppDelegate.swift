import AppKit
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let hotKeyTap = HotKeyTap()
    private var panelController: PanelController!
    private var settingsController: SettingsController!
    private var previousApp: NSRunningApplication?

    func applicationDidFinishLaunching(_ notification: Notification) {
        panelController = PanelController()
        panelController.onCommit = { [weak self] text in self?.commit(text) }
        settingsController = SettingsController()
        settingsController.model.onHotKeyChanged = { [weak self] in
            self?.hotKeyTap.reloadHotKey()
        }

        setUpStatusItem()

        hotKeyTap.onHotKey = { [weak self] in self?.openFromHotKey() }
        hotKeyTap.start()

        // パネルを開いたまま他アプリへ移動しても、最後にいたアプリへ貼り付けられるよう追跡する
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(frontAppChanged(_:)),
            name: NSWorkspace.didActivateApplicationNotification, object: nil)

        // 初回起動、または権限が未許可なら設定（オンボーディング）を表示
        if !Prefs.didOnboard || !AXIsProcessTrusted() {
            Prefs.didOnboard = true
            settingsController.show()
        }

        if CommandLine.arguments.contains("--show") {
            openFromMenu()
        }
        if let i = CommandLine.arguments.firstIndex(of: "--snapshot"),
           CommandLine.arguments.count > i + 1 {
            snapshot(to: CommandLine.arguments[i + 1])
        }
        if let i = CommandLine.arguments.firstIndex(of: "--snapshot-settings"),
           CommandLine.arguments.count > i + 1 {
            snapshotSettings(to: CommandLine.arguments[i + 1])
        }
        if let i = CommandLine.arguments.firstIndex(of: "--record-demo"),
           CommandLine.arguments.count > i + 1 {
            let path = CommandLine.arguments[i + 1]
            if CommandLine.arguments.contains("--dark") {
                NSApp.appearance = NSAppearance(named: .darkAqua)
            } else if CommandLine.arguments.contains("--light") {
                NSApp.appearance = NSAppearance(named: .aqua)
            }
            DispatchQueue.main.async {
                DemoRecorder.record(to: path)
                NSApp.terminate(nil)
            }
        }
    }

    /// デバッグ用: 設定画面をPNGに書き出して終了
    private func snapshotSettings(to path: String) {
        if CommandLine.arguments.contains("--dark") {
            NSApp.appearance = NSAppearance(named: .darkAqua)
        } else if CommandLine.arguments.contains("--light") {
            NSApp.appearance = NSAppearance(named: .aqua)
        }
        settingsController.show()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let view = self?.settingsController.contentViewForSnapshot(),
                  let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
                NSApp.terminate(nil); return
            }
            view.cacheDisplay(in: view.bounds, to: rep)
            if let data = rep.representation(using: .png, properties: [:]) {
                try? data.write(to: URL(fileURLWithPath: path))
            }
            NSApp.terminate(nil)
        }
    }

    /// デバッグ用: サンプル状態のUIをPNGに書き出して終了
    private func snapshot(to path: String) {
        if CommandLine.arguments.contains("--dark") {
            NSApp.appearance = NSAppearance(named: .darkAqua)
        } else if CommandLine.arguments.contains("--light") {
            NSApp.appearance = NSAppearance(named: .aqua)
        }
        let m = panelController.model
        let cal = m.calendar
        let today = cal.startOfDay(for: Date())
        let in1 = cal.date(byAdding: .day, value: 1, to: today)!
        let in10 = cal.date(byAdding: .day, value: 10, to: today)!
        panelController.show()   // prepareForOpen で状態がリセットされるので先に呼ぶ
        m.slots = [
            Slot(date: today, start: 9 * 60, end: 12 * 60),
            Slot(date: today, start: 14 * 60, end: 15 * 60),
            Slot(date: in1, start: 12 * 60, end: 13 * 60),
            Slot(date: in10, start: 9 * 60 + 30, end: 18 * 60 + 30),
        ]
        m.activeDate = in1
        m.pendingStart = 10 * 60
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let view = self?.panelController.contentViewForSnapshot(),
                  let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
                NSApp.terminate(nil); return
            }
            view.cacheDisplay(in: view.bounds, to: rep)
            if let data = rep.representation(using: .png, properties: [:]) {
                try? data.write(to: URL(fileURLWithPath: path))
            }
            print(m.outputText)
            NSApp.terminate(nil)
        }
    }

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "calendar.badge.plus",
            accessibilityDescription: "日程送るくん")

        let menu = NSMenu()
        let openItem = NSMenuItem(title: "開く", action: #selector(openFromMenu), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
        let settingsItem = NSMenuItem(
            title: "設定…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "終了", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func openSettings() {
        settingsController.show()
    }

    @objc private func frontAppChanged(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                as? NSRunningApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier
        else { return }
        previousApp = app
    }

    private func openFromHotKey() {
        guard !panelController.isVisible else {
            panelController.bringToFront()
            return
        }
        previousApp = NSWorkspace.shared.frontmostApplication
        panelController.show()
    }

    @objc private func openFromMenu() {
        previousApp = NSWorkspace.shared.frontmostApplication
        panelController.show()
    }

    private func commit(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        panelController.model.reset()
        panelController.close()

        // 元のアプリに戻って貼り付け
        if let previous = previousApp, previous.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            previous.activate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                Paste.sendCmdV()
            }
        }
    }
}
