import Foundation
import PeekMemoCore

enum DateHeaderTextTests {
    static func run() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let today = try date(2026, 10, 1, calendar)
        let english = Locale(identifier: "en_US")
        let chinese = Locale(identifier: "zh_CN")

        try expectEqual(
            DateHeaderText.format(selected: today, now: today, calendar: calendar, locale: english),
            "Oct 1 · Thu · Today"
        )
        try expectEqual(
            DateHeaderText.format(selected: try date(2026, 9, 30, calendar), now: today, calendar: calendar, locale: english),
            "Sep 30 · Wed"
        )
        try expectEqual(
            DateHeaderText.format(selected: try date(2026, 10, 2, calendar), now: today, calendar: calendar, locale: english),
            "Oct 2 · Fri"
        )
        try expectEqual(
            DateHeaderText.format(selected: try date(2027, 10, 1, calendar), now: today, calendar: calendar, locale: english),
            "Oct 1, 2027 · Fri"
        )
        try expectEqual(
            DateHeaderText.format(selected: today, now: today, calendar: calendar, locale: chinese),
            "10月1日 · 周四 · 今天"
        )
        try expectEqual(
            DateHeaderText.format(selected: try date(2026, 10, 2, calendar), now: today, calendar: calendar, locale: chinese),
            "10月2日 · 周五"
        )
        try expectEqual(
            DateHeaderText.format(selected: try date(2027, 10, 1, calendar), now: today, calendar: calendar, locale: chinese),
            "2027年10月1日 · 周五"
        )
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int, _ calendar: Calendar) throws -> Date {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = 12
        guard let date = calendar.date(from: parts) else {
            throw CheckError(message: "could not build \(year)-\(month)-\(day)")
        }
        return date
    }
}
