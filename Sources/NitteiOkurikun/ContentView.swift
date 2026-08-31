import SwiftUI

// MARK: - デザイントークン（参考サイトのトーン）

enum Theme {
    private static func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> NSColor {
        NSColor(red: r, green: g, blue: b, alpha: 1)
    }
    private static func dynamicNS(light: NSColor, dark: NSColor) -> NSColor {
        NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        }
    }
    private static func dyn(_ light: NSColor, _ dark: NSColor) -> Color {
        Color(nsColor: dynamicNS(light: light, dark: dark))
    }

    /// パネル背景用（NSPanel.backgroundColor にも使う）
    static let backgroundNS = dynamicNS(
        light: rgb(0.945, 0.941, 0.918),   // #F1F0EA
        dark: rgb(0.106, 0.104, 0.096))    // 暖色系のダークグレー
    static let background = Color(nsColor: backgroundNS)

    static let card = dyn(rgb(1, 1, 1), rgb(0.165, 0.161, 0.149))
    static let ink = dyn(rgb(0.18, 0.18, 0.18), rgb(0.93, 0.92, 0.89))
    static let inkFaint = dyn(rgb(0.55, 0.55, 0.55), rgb(0.60, 0.59, 0.56))
    static let sunday = dyn(rgb(0.80, 0.25, 0.22), rgb(0.93, 0.47, 0.43))
    static let saturday = dyn(rgb(0.25, 0.42, 0.78), rgb(0.50, 0.65, 0.95))
    static let accent = dyn(rgb(0.10, 0.10, 0.10), rgb(0.96, 0.95, 0.92))
    /// accent の上に載せる文字色
    static let onAccent = dyn(rgb(1, 1, 1), rgb(0.10, 0.10, 0.10))
    static let chipBorder = dyn(rgb(0.88, 0.87, 0.84), rgb(0.28, 0.28, 0.26))
    static let cardRadius: CGFloat = 16
}

struct ContentView: View {
    @ObservedObject var model: ScheduleModel
    var onCommit: (String) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 14) {
                CalendarCard(model: model)
                TimeChipsCard(model: model)
            }
            .frame(width: 430)
            PreviewCard(model: model, onCommit: onCommit)
                .frame(width: 300)
        }
        .padding(16)
        .frame(width: 790)
        .background(Theme.background)
    }
}

// MARK: - カード共通

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .fill(Theme.card)
                    .shadow(color: .black.opacity(0.06), radius: 10, y: 3)
            )
    }
}

// MARK: - カレンダー

struct CalendarCard: View {
    @ObservedObject var model: ScheduleModel

    private var monthTitle: String {
        let c = model.calendar.dateComponents([.year, .month], from: model.displayedMonth)
        return "\(c.year!)年\(c.month!)月"
    }

    /// 表示月の日付を「週頭の空セル(nil)＋各日」で並べたもの
    private var cells: [Date?] {
        let cal = model.calendar
        let first = model.displayedMonth
        let weekday = cal.component(.weekday, from: first) - 1 // 日曜=0
        let days = cal.range(of: .day, in: .month, for: first)!.count
        var result: [Date?] = Array(repeating: nil, count: weekday)
        for day in 0..<days {
            result.append(cal.date(byAdding: .day, value: day, to: first)!)
        }
        return result
    }

    var body: some View {
        Card {
            VStack(spacing: 10) {
                HStack {
                    NavButton(symbol: "chevron.left") { model.moveMonth(by: -1) }
                    Spacer()
                    Text(monthTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    NavButton(symbol: "chevron.right") { model.moveMonth(by: 1) }
                }
                let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(0..<7, id: \.self) { i in
                        Text(ScheduleModel.weekdaySymbols[i])
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(weekdayColor(i))
                    }
                    ForEach(Array(cells.enumerated()), id: \.offset) { _, date in
                        if let date {
                            DayCell(model: model, date: date)
                        } else {
                            Color.clear.frame(height: 30)
                        }
                    }
                }
            }
        }
    }

    private func weekdayColor(_ index: Int) -> Color {
        index == 0 ? Theme.sunday : index == 6 ? Theme.saturday : Theme.inkFaint
    }
}

struct NavButton: View {
    let symbol: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.inkFaint)
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct DayCell: View {
    @ObservedObject var model: ScheduleModel
    let date: Date

    private var isActive: Bool { model.activeDate == date }
    private var isToday: Bool { model.calendar.isDateInToday(date) }
    private var weekdayIndex: Int { model.calendar.component(.weekday, from: date) - 1 }

    var body: some View {
        Button { model.selectDate(date) } label: {
            VStack(spacing: 1) {
                Text("\(model.calendar.component(.day, from: date))")
                    .font(.system(size: 12, weight: isActive || isToday ? .bold : .regular))
                    .monospacedDigit()
                    .foregroundStyle(textColor)
                Circle()
                    .fill(model.hasSlot(on: date) ? Theme.accent : .clear)
                    .frame(width: 4, height: 4)
                    .opacity(isActive ? 0 : 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isActive ? Theme.accent : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isToday && !isActive ? Theme.chipBorder : .clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var textColor: Color {
        if isActive { return Theme.onAccent }
        if weekdayIndex == 0 { return Theme.sunday }
        if weekdayIndex == 6 { return Theme.saturday }
        return Theme.ink
    }
}

// MARK: - 時間チップ

struct TimeChipsCard: View {
    @ObservedObject var model: ScheduleModel

    private static let times: [Int] = stride(from: 8 * 60, through: 22 * 60 + 30, by: 30).map { $0 }

    private var hint: String {
        if model.activeDate == nil { return "カレンダーで日付を選択" }
        if model.pendingStart == nil { return "開始時刻を選択" }
        return "終了時刻を選択"
    }

    var body: some View {
        Card {
            VStack(spacing: 10) {
                HStack {
                    Text(hint)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(model.activeDate == nil ? Theme.inkFaint : Theme.ink)
                    Spacer()
                    if let date = model.activeDate {
                        Text(model.dateLabel(for: date))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.ink)
                    }
                }
                let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 6)
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(Self.times, id: \.self) { minutes in
                        TimeChip(model: model, minutes: minutes)
                    }
                }
                .opacity(model.activeDate == nil ? 0.35 : 1)
            }
        }
    }
}

struct TimeChip: View {
    @ObservedObject var model: ScheduleModel
    let minutes: Int

    private var isStart: Bool { model.pendingStart == minutes }

    var body: some View {
        Button { model.tapTime(minutes) } label: {
            Text(ScheduleModel.timeString(minutes))
                .font(.system(size: 11.5, weight: isStart ? .bold : .regular))
                .monospacedDigit()
                .foregroundStyle(isStart ? Theme.onAccent : Theme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 26)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isStart ? Theme.accent : Theme.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(Theme.chipBorder, lineWidth: 1)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(model.activeDate == nil)
    }
}

// MARK: - プレビュー

struct PreviewCard: View {
    @ObservedObject var model: ScheduleModel
    var onCommit: (String) -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                if model.slots.isEmpty {
                    Text("日付と時間を選ぶと\nここに表示されます")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.inkFaint)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(ScheduleModel.header)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(Theme.ink)
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(model.slots) { slot in
                            SlotRow(model: model, slot: slot)
                        }
                    }
                }
                Spacer(minLength: 0)
                VStack(spacing: 8) {
                    Button {
                        onCommit(model.outputText)
                    } label: {
                        Text("コピーする")
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundStyle(model.slots.isEmpty ? .white : Theme.onAccent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(
                                Capsule().fill(model.slots.isEmpty ? Color.gray.opacity(0.35)
                                                                   : Theme.accent)
                            )
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(model.slots.isEmpty)
                    .keyboardShortcut(.defaultAction)

                    Button("リセットする") { model.reset() }
                        .buttonStyle(.plain)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.inkFaint)

                    Text("コピーと同時に、元のアプリへ貼り付けます")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.inkFaint.opacity(0.8))
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxHeight: .infinity)
    }
}

struct SlotRow: View {
    @ObservedObject var model: ScheduleModel
    let slot: Slot

    /// 同じ日の最初のスロットだけ日付ラベルを出す（出力の「,」区切りと同じ見え方）
    private var isFirstOfDay: Bool {
        model.slots.first { model.calendar.isDate($0.date, inSameDayAs: slot.date) }?.id == slot.id
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(isFirstOfDay ? model.dateLabel(for: slot.date) : "")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.ink)
                .frame(width: 96, alignment: .leading)
            Text(ScheduleModel.rangeString(slot))
                .font(.system(size: 12))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
            Spacer()
            Button {
                model.removeSlot(slot)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkFaint.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }
}
