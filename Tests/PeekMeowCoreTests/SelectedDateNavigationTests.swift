import Foundation
import PeekMeowCore

enum SelectedDateNavigationTests {
    static func run() throws {
        try shiftMovesOneDay()
        try startOfDayIsStable()
    }

    static func shiftMovesOneDay() throws {
        let calendar = Calendar(identifier: .gregorian)
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        let next = DailyView.shiftDay(day, by: 1, calendar: calendar)
        let prev = DailyView.shiftDay(day, by: -1, calendar: calendar)
        try expect(!DailyView.isSameDay(day, next, calendar: calendar))
        try expect(!DailyView.isSameDay(day, prev, calendar: calendar))
        try expect(DailyView.isSameDay(DailyView.shiftDay(next, by: -1, calendar: calendar), day, calendar: calendar))
    }

    static func startOfDayIsStable() throws {
        let calendar = Calendar(identifier: .gregorian)
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        let a = DailyView.startOfDay(day, calendar: calendar)
        let b = DailyView.startOfDay(a.addingTimeInterval(10_000), calendar: calendar)
        try expect(DailyView.isSameDay(a, b, calendar: calendar))
    }
}
