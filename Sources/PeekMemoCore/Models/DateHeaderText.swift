import Foundation

/// Shared date header. Weekday and the Today word come from the locale, not a hardcoded English list.
public enum DateHeaderText: Sendable {
    public static func format(
        selected: Date,
        now: Date,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> String {
        var calendar = calendar
        calendar.locale = locale
        let day = calendar.startOfDay(for: selected)
        let today = calendar.startOfDay(for: now)
        let includeYear = calendar.component(.year, from: day) != calendar.component(.year, from: today)
        let dateText = dateString(day, includeYear: includeYear, calendar: calendar, locale: locale)
        let weekday = weekdayString(day, calendar: calendar, locale: locale)
        if calendar.isDate(day, inSameDayAs: today) {
            return "\(dateText) · \(weekday) · \(todayWord(now: today, calendar: calendar, locale: locale))"
        }
        return "\(dateText) · \(weekday)"
    }

    private static func dateString(
        _ date: Date,
        includeYear: Bool,
        calendar: Calendar,
        locale: Locale
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        if locale.language.languageCode?.identifier == "zh" {
            formatter.dateFormat = includeYear ? "yyyy年M月d日" : "M月d日"
            return formatter.string(from: date)
        }
        formatter.setLocalizedDateFormatFromTemplate(includeYear ? "yMMMd" : "MMMd")
        return formatter.string(from: date)
    }

    private static func weekdayString(_ date: Date, calendar: Calendar, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter.string(from: date)
    }

    private static func todayWord(now: Date, calendar: Calendar, locale: Locale) -> String {
        let relative = DateFormatter()
        relative.calendar = calendar
        relative.locale = locale
        relative.dateStyle = .medium
        relative.timeStyle = .none
        relative.doesRelativeDateFormatting = true
        let plain = DateFormatter()
        plain.calendar = calendar
        plain.locale = locale
        plain.dateStyle = .medium
        plain.timeStyle = .none
        let relativeText = relative.string(from: now)
        if relativeText != plain.string(from: now), !relativeText.isEmpty {
            return relativeText
        }
        if locale.language.languageCode?.identifier == "zh" {
            return "今天"
        }
        return "Today"
    }
}
