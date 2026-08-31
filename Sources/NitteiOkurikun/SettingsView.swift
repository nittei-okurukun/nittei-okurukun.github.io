import SwiftUI
import ServiceManagement

final class SettingsModel: ObservableObject {
    @Published var trusted = AXIsProcessTrusted()
    @Published var hotKeyDisplay = Prefs.hotKey.display
    @Published var launchAtLogin = SMAppService.mainApp.status == .enabled
    @Published var isRecording = false
    var onHotKeyChanged: (() -> Void)?

    func refresh() {
        trusted = AXIsProcessTrusted()
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
        let url = URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {}
        refresh()
    }

    func apply(hotKey: Prefs.HotKey) {
        Prefs.hotKey = hotKey
        hotKeyDisplay = hotKey.display
        onHotKeyChanged?()
    }
}

struct SettingsView: View {
    @ObservedObject var model: SettingsModel
    @State private var keyMonitor: Any?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // ヘッダー
            VStack(alignment: .leading, spacing: 4) {
                Text("日程送るくん")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("候補日時をサッと選んで、そのまま送れる文面に。")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkFaint)
            }

            Card {
                VStack(alignment: .leading, spacing: 8) {
                    Text("使い方").font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.inkFaint)
                    step("1", model.hotKeyDisplay.hasSuffix("N")
                         ? "メールやチャットの入力欄で \(model.hotKeyDisplay) を押す（Nは日程のN）"
                         : "メールやチャットの入力欄で \(model.hotKeyDisplay) を押す")
                    step("2", "日付 → 開始 → 終了の順にクリック（複数日OK）")
                    step("3", "「コピーする」で元のアプリにそのまま貼り付け")
                }
            }

            Card {
                VStack(alignment: .leading, spacing: 12) {
                    // アクセシビリティ
                    HStack(spacing: 8) {
                        Circle()
                            .fill(model.trusted ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("アクセシビリティ")
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundStyle(Theme.ink)
                            Text(model.trusted
                                 ? "許可済み。ホットキーが使えます"
                                 : "ホットキーの監視と自動貼り付けに必要です")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.inkFaint)
                        }
                        Spacer()
                        if !model.trusted {
                            Button("許可する") { model.requestAccessibility() }
                                .buttonStyle(.plain)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Theme.onAccent)
                                .padding(.horizontal, 14).padding(.vertical, 6)
                                .background(Capsule().fill(Theme.accent))
                        }
                    }
                    Divider()
                    // ホットキー
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ホットキー")
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundStyle(Theme.ink)
                            Text("⌘ か ⌃ を含む組み合わせを設定できます")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.inkFaint)
                        }
                        Spacer()
                        Button {
                            model.isRecording ? stopRecording() : startRecording()
                        } label: {
                            Text(model.isRecording ? "キーを入力…" : model.hotKeyDisplay)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(model.isRecording ? Theme.inkFaint : Theme.ink)
                                .frame(minWidth: 70)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(Theme.chipBorder, lineWidth: 1)
                                )
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    Divider()
                    // ログイン時に起動
                    HStack {
                        Text("ログイン時に自動で起動")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { model.launchAtLogin },
                            set: { model.setLaunchAtLogin($0) }))
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .labelsHidden()
                    }
                }
            }

            Text("すべての処理はMacの中だけで完結します。ネットワーク通信は行いません。")
                .font(.system(size: 10.5))
                .foregroundStyle(Theme.inkFaint.opacity(0.85))
        }
        .padding(20)
        .frame(width: 420)
        .background(Theme.background)
        .onDisappear { stopRecording() }
    }

    private func step(_ n: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(n)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Theme.onAccent)
                .frame(width: 16, height: 16)
                .background(Circle().fill(Theme.accent))
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(Theme.ink)
        }
    }

    // MARK: - ホットキー録音

    private func startRecording() {
        model.isRecording = true
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            defer { stopRecording() }
            if event.keyCode == 53 { return nil }   // Esc でキャンセル
            let mods = event.modifierFlags.intersection([.command, .control, .option, .shift])
            guard mods.contains(.command) || mods.contains(.control) else {
                NSSound.beep()
                return nil
            }
            let display = Prefs.displayString(
                keyCode: event.keyCode, modifiers: mods,
                characters: event.charactersIgnoringModifiers)
            model.apply(hotKey: Prefs.HotKey(
                keyCode: Int64(event.keyCode), modifiers: mods, display: display))
            return nil
        }
    }

    private func stopRecording() {
        model.isRecording = false
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }
}
