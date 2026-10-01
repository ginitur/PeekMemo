namespace PeekMeow.Core.Daily;

/// A civil day in a time zone. `scheduledDate` falls on this day when its local date matches.
public readonly record struct CivilDay(DateOnly Date, TimeZoneInfo Zone)
{
    public static CivilDay From(DateTimeOffset instant, TimeZoneInfo zone)
    {
        var local = TimeZoneInfo.ConvertTime(instant, zone);
        return new CivilDay(DateOnly.FromDateTime(local.DateTime), zone);
    }

    public bool Contains(DateTimeOffset instant) => From(instant, Zone).Date == Date;
}
