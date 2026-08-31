import Foundation

struct Slot: Identifiable, Equatable {
    let id = UUID()
    var date: Date          // その日の 0:00
    var start: Int          // 0:00 からの分
    var end: Int
}

final class ScheduleModel: ObservableObject {
    @Published var displayedMonth: Date   // 表示中の月の1日
    @Published var activeDate: Date?      // 時刻選択中の日付
    @Published var pendingStart: Int?     // 開始時刻（選択途中）
    @Published var slots: [Slot] = []

    static let header = "以下の日程でご予定はいかがでしょうか。"
    static let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "ja_JP")
        return c
    }()

    init() {
        let now = Date()
        displayedMonth = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: now))!
    }

    /// パネルを開くたびに「今日の月」へ戻す
    func prepareForOpen() {
        let now = Date()
        displayedMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: now))!
        activeDate = nil
        pendingStart = nil
    }

    func reset() {
        slots = []
        activeDate = nil
        pendingStart = nil
    }

    func moveMonth(by offset: Int) {
        displayedMonth = calendar.date(byAdding: .month, value: offset, to: displayedMonth)!
    }

    func selectDate(_ date: Date) {
        if activeDate == date {
            activeDate = nil
        } else {
            activeDate = date
        }
        pendingStart = nil
    }

    func tapTime(_ minutes: Int) {
        guard activeDate != nil else { return }
        if let start = pendingStart, minutes > start, let date = activeDate {
            slots.append(Slot(date: date, start: start, end: minutes))
            slots.sort { ($0.date, $0.start) < ($1.date, $1.start) }
            pendingStart = nil
            activeDate = nil
        } else {
            // 未選択、または開始以前のチップ → 新しい開始時刻として扱う
            pendingStart = minutes
        }
    }

    func removeSlot(_ slot: Slot) {
        slots.removeAll { $0.id == slot.id }
    }

    func hasSlot(on date: Date) -> Bool {
        slots.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }

    // MARK: - 出力

    static func timeString(_ minutes: Int) -> String {
        String(format: "%d:%02d", minutes / 60, minutes % 60)
    }

    func dateLabel(for date: Date) -> String {
        let comps = calendar.dateComponents([.month, .day, .weekday], from: date)
        let weekday = Self.weekdaySymbols[(comps.weekday ?? 1) - 1]
        return "\(comps.month!)月\(comps.day!)日（\(weekday)）"
    }

    static func rangeString(_ slot: Slot) -> String {
        "\(timeString(slot.start))〜\(timeString(slot.end))"
    }

    /// 日付ごとに1行。同じ日の複数時間帯は「,」区切りでまとめる
    var groupedLines: [(date: Date, text: String)] {
        var result: [(Date, String)] = []
        for slot in slots {  // slots は日付・開始時刻順にソート済み
            if let last = result.last, calendar.isDate(last.0, inSameDayAs: slot.date) {
                result[result.count - 1].1 += ",\(Self.rangeString(slot))"
            } else {
                result.append((slot.date, "\(dateLabel(for: slot.date))　\(Self.rangeString(slot))"))
            }
        }
        return result
    }

    var outputText: String {
        ([Self.header] + groupedLines.map(\.text)).joined(separator: "\n")
    }
}
