using System.Globalization;
using PeekMeow.Core.Daily;
using Xunit;

namespace PeekMeow.Windows.Tests;

public class DateTitleTests
{
    static readonly DateOnly Today = new(2026, 10, 1);
    static readonly CultureInfo English = CultureInfo.GetCultureInfo("en-US");
    static readonly CultureInfo Chinese = CultureInfo.GetCultureInfo("zh-CN");

    [Fact]
    public void EnglishTodayIncludesWeekdayAndToday()
    {
        Assert.Equal("Oct 1 · Thu · Today", DateTitle.Format(Today, true, English, 2026));
        Assert.Equal("Sep 30 · Wed", DateTitle.Format(new DateOnly(2026, 9, 30), false, English, 2026));
        Assert.Equal("Oct 2 · Fri", DateTitle.Format(new DateOnly(2026, 10, 2), false, English, 2026));
    }

    [Fact]
    public void OtherYearsIncludeTheYear()
    {
        Assert.Equal("Oct 1, 2027 · Fri", DateTitle.Format(new DateOnly(2027, 10, 1), false, English, 2026));
        Assert.Equal("2027年10月1日 · 周五", DateTitle.Format(new DateOnly(2027, 10, 1), false, Chinese, 2026));
    }

    [Fact]
    public void ChineseUsesLocaleWeekdayWithoutHardcodedEnglish()
    {
        Assert.Equal("10月1日 · 周四 · 今天", DateTitle.Format(Today, true, Chinese, 2026));
        Assert.Equal("10月2日 · 周五", DateTitle.Format(new DateOnly(2026, 10, 2), false, Chinese, 2026));
    }
}
