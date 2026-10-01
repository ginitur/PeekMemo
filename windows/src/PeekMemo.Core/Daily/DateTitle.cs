using System.Globalization;

namespace PeekMemo.Core.Daily;

public static class DateTitle
{
    /// Today in the current year is "Oct 1 · Thu · Today". Other days drop Today.
    /// A different year adds the year. Weekday comes from the culture.
    public static string Format(DateOnly date, bool isToday) =>
        Format(date, isToday, CultureInfo.CurrentCulture, DateTime.Now.Year);

    public static string Format(DateOnly date, bool isToday, CultureInfo culture, int currentYear)
    {
        var dateText = DateText(date, culture, date.Year != currentYear);
        var weekday = date.ToDateTime(TimeOnly.MinValue).ToString("ddd", culture);
        if (isToday && date.Year == currentYear)
        {
            return dateText + " · " + weekday + " · " + TodayWord(culture);
        }

        return dateText + " · " + weekday;
    }

    static string DateText(DateOnly date, CultureInfo culture, bool includeYear)
    {
        var pattern = culture.TwoLetterISOLanguageName == "zh"
            ? includeYear ? "yyyy年M月d日" : "M月d日"
            : includeYear ? "MMM d, yyyy" : "MMM d";
        return date.ToString(pattern, culture);
    }

    static string TodayWord(CultureInfo culture) => culture.TwoLetterISOLanguageName switch
    {
        "zh" => "今天",
        "ja" => "今日",
        "ko" => "오늘",
        "fr" => "aujourd’hui",
        "de" => "Heute",
        "es" => "hoy",
        _ => "Today"
    };
}
