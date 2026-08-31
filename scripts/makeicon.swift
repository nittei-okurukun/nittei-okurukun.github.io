// アプリアイコン生成スクリプト
// 使い方: swift scripts/makeicon.swift <出力ディレクトリ(.iconset)>
import AppKit

let charcoal = NSColor(red: 0.110, green: 0.106, blue: 0.094, alpha: 1)
let beige = NSColor(red: 0.945, green: 0.941, blue: 0.918, alpha: 1)
let accent = NSColor(red: 0.831, green: 0.329, blue: 0.290, alpha: 1)

func render(_ pixels: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(pixels)

    // macOS流: 余白つきの角丸スクエア（ダーク）
    let inset = s * 0.085
    let bgRect = NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    charcoal.setFill()
    NSBezierPath(roundedRect: bgRect, xRadius: bgRect.width * 0.235,
                 yRadius: bgRect.width * 0.235).fill()

    // カレンダーを想起させる 3x3 グリッド。右下手前の1マスをアクセント色に
    let cell = s * 0.155
    let gap = s * 0.055
    let total = cell * 3 + gap * 2
    let origin = (s - total) / 2
    for row in 0..<3 {
        for col in 0..<3 {
            let isAccent = (row == 0 && col == 2)   // 下段右（rowは下から）
            (isAccent ? accent : beige).setFill()
            let r = NSRect(x: origin + CGFloat(col) * (cell + gap),
                           y: origin + CGFloat(row) * (cell + gap),
                           width: cell, height: cell)
            NSBezierPath(roundedRect: r, xRadius: cell * 0.28, yRadius: cell * 0.28).fill()
        }
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
let entries: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
for (name, px) in entries {
    let rep = render(px)
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: "\(outDir)/\(name).png"))
}
print("iconset generated: \(outDir)")
