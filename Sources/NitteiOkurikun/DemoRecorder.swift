import AppKit
import SwiftUI
import AVFoundation

/// デモ動画用の演出状態
final class DemoState: ObservableObject {
    @Published var bodyText = ""
    @Published var caretOn = true
    @Published var keycapOpacity: Double = 0
    @Published var panelOpacity: Double = 0
    let model = ScheduleModel()
}

/// メール風ウインドウ + 実物のパネルを並べたデモシーン
struct DemoScene: View {
    @ObservedObject var state: DemoState
    @ObservedObject var model: ScheduleModel

    var body: some View {
        ZStack {
            Theme.background
            compose
                .frame(width: 620)
                .position(x: 350, y: 375)
            ContentView(model: model, onCommit: { _ in })
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.28), radius: 34, y: 14)
                .scaleEffect(0.76 + 0.04 * state.panelOpacity)
                .opacity(state.panelOpacity)
                .position(x: 790, y: 378)
        }
        .frame(width: 1200, height: 750)
    }

    private var compose: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                Circle().fill(Color(red: 1, green: 0.37, blue: 0.35)).frame(width: 12, height: 12)
                Circle().fill(Color(red: 1, green: 0.74, blue: 0.18)).frame(width: 12, height: 12)
                Circle().fill(Color(red: 0.2, green: 0.78, blue: 0.35)).frame(width: 12, height: 12)
                Spacer()
                Text("新規メッセージ")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.inkFaint)
                Spacer()
                Color.clear.frame(width: 50, height: 1)
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            Divider()
            field("宛先:", "佐藤さま")
            Divider().padding(.leading, 14)
            field("件名:", "打ち合わせの日程について")
            Divider()
            VStack(alignment: .leading, spacing: 14) {
                (Text(state.bodyText)
                    .font(.system(size: 13.5))
                    .foregroundColor(Theme.ink)
                 + Text(state.caretOn ? "▏" : " ")
                    .font(.system(size: 13.5))
                    .foregroundColor(Theme.ink))
                    .lineSpacing(6)
                HStack(spacing: 8) {
                    Text("⌃⌘N")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Theme.background)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Theme.chipBorder, lineWidth: 1)
                        )
                    Text("日程送るくんを呼び出し")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.inkFaint)
                }
                .opacity(state.keycapOpacity)
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 380, alignment: .topLeading)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.card)
                .shadow(color: .black.opacity(0.12), radius: 22, y: 8)
        )
    }

    private func field(_ label: String, _ value: String) -> some View {
        HStack(spacing: 8) {
            Text(label).font(.system(size: 12.5)).foregroundStyle(Theme.inkFaint)
            Text(value).font(.system(size: 12.5)).foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
    }
}

enum DemoRecorder {
    static let fps = 20
    static func at(_ sec: Double) -> Int { Int(sec * Double(fps)) }
    static let totalFrames = at(17.0)

    static let intro = "お疲れさまです。\n次回の打ち合わせの日程ですが、"

    /// フレーム番号に応じて演出状態を更新する（タイムライン本体）
    static func apply(frame f: Int, state: DemoState) {
        let model = state.model
        state.caretOn = (f / 8) % 2 == 0

        if f <= at(2.0) {
            let n = intro.count * f / at(2.0)
            state.bodyText = String(intro.prefix(n))
        }
        if f >= at(2.2), f < at(3.4) {
            state.keycapOpacity = min(1, Double(f - at(2.2)) / 6)
        }
        if f >= at(3.4) {
            state.keycapOpacity = max(0, 1 - Double(f - at(3.4)) / 6)
            state.panelOpacity = min(1, Double(f - at(3.4)) / 8)
        }

        let cal = model.calendar
        let d1 = cal.date(byAdding: .day, value: 9, to: model.weekStart)!
        let d2 = cal.date(byAdding: .day, value: 18, to: model.weekStart)!
        if f == at(4.4) { model.selectDate(d1) }
        if f == at(5.0) { model.tapTime(10 * 60) }
        if f == at(5.8) { model.tapTime(11 * 60) }
        if f == at(6.6) { model.selectDate(d1) }
        if f == at(7.2) { model.tapTime(14 * 60) }
        if f == at(8.0) { model.tapTime(15 * 60) }
        if f == at(8.8) { model.selectDate(d2) }
        if f == at(9.4) { model.tapTime(9 * 60 + 30) }
        if f == at(10.2) { model.tapTime(12 * 60) }

        if f >= at(11.0) {
            state.panelOpacity = max(0, 1 - Double(f - at(11.0)) / 8)
        }
        if f >= at(11.6) {
            let full = intro + "\n\n" + model.outputText
            let span = at(14.0) - at(11.6)
            let progress = min(f - at(11.6), span)
            let n = intro.count + (full.count - intro.count) * progress / span
            state.bodyText = String(full.prefix(n))
        }
    }

    /// シーンをオフスクリーンでフレームごとに描画し、H.264 mp4 に書き出す
    static func record(to path: String) {
        let state = DemoState()
        let hosting = NSHostingView(rootView: DemoScene(state: state, model: state.model))
        hosting.frame = CGRect(x: 0, y: 0, width: 1200, height: 750)
        let window = NSWindow(
            contentRect: hosting.frame, styleMask: [.borderless],
            backing: .buffered, defer: false)
        window.contentView = hosting
        spin()

        // 最初のフレームでピクセルサイズを確定してからライターを作る
        guard let probe = capture(hosting) else { fatalError("render failed") }
        let w = probe.pixelsWide, h = probe.pixelsHigh

        let url = URL(fileURLWithPath: path)
        try? FileManager.default.removeItem(at: url)
        let writer = try! AVAssetWriter(outputURL: url, fileType: .mp4)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: w, AVVideoHeightKey: h,
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 4_000_000],
        ])
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: w,
                kCVPixelBufferHeightKey as String: h,
            ])
        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        let posterFrame = at(8.2)
        for f in 0...totalFrames {
            apply(frame: f, state: state)
            spin()
            guard let rep = capture(hosting), let cg = rep.cgImage else { continue }
            while !input.isReadyForMoreMediaData { spin() }
            if let buffer = pixelBuffer(from: cg, pool: adaptor.pixelBufferPool, width: w, height: h) {
                adaptor.append(buffer, withPresentationTime:
                    CMTime(value: CMTimeValue(f), timescale: CMTimeScale(fps)))
            }
            if f == posterFrame, let data = rep.representation(using: .png, properties: [:]) {
                let posterPath = (path as NSString).deletingPathExtension + "-poster.png"
                try? data.write(to: URL(fileURLWithPath: posterPath))
            }
        }

        input.markAsFinished()
        var done = false
        writer.finishWriting { done = true }
        while !done { spin() }
        print("demo written: \(path) (\(w)x\(h), \(totalFrames) frames)")
    }

    private static func spin() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.02))
    }

    private static func capture(_ view: NSView) -> NSBitmapImageRep? {
        view.layoutSubtreeIfNeeded()
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return nil }
        view.cacheDisplay(in: view.bounds, to: rep)
        return rep
    }

    private static func pixelBuffer(from image: CGImage, pool: CVPixelBufferPool?,
                                    width: Int, height: Int) -> CVPixelBuffer? {
        var buffer: CVPixelBuffer?
        if let pool {
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
        } else {
            CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32ARGB, nil, &buffer)
        }
        guard let buffer else { return nil }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let ctx = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else { return nil }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return buffer
    }
}
