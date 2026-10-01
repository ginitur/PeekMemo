using System.Globalization;

namespace PeekMemo.Core.Daily;

public static class DateTitle
{
    static readonly CultureInfo English = CultureInfo.GetCultureInfo("en-US");

    /// "Oct 1 · Today" when the selected day is today. Otherwise "Oct 1".
    public static string Format(DateOnly date, bool isToday)
    {
        var text = date.ToString("MMM d", English);
        return isToday ? text + " · Today" : text;
    }
}
