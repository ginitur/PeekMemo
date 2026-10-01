using System.Globalization;

namespace PeekMemo.Persistence;

/// Civil days become the UTC instant of that day's local start. Instants are UTC.
/// Callers pass the zone. Nothing else in the repositories converts dates.
public sealed class DateStorageMapper
{
    public const string Format = "yyyy-MM-dd'T'HH:mm:ss.fff'Z'";

    readonly TimeZoneInfo _zone;

    public DateStorageMapper(TimeZoneInfo zone)
    {
        _zone = zone ?? throw new ArgumentNullException(nameof(zone));
    }

    public TimeZoneInfo Zone => _zone;

    public string StoreDay(DateOnly day) => FormatUtc(ToUtc(day.ToDateTime(TimeOnly.MinValue), _zone));

    public DateOnly ReadDay(string stored)
    {
        var utc = ParseUtc(stored);
        var local = TimeZoneInfo.ConvertTimeFromUtc(utc, _zone);
        return DateOnly.FromDateTime(local);
    }

    public (string Start, string Next) DayRange(DateOnly day) =>
        (StoreDay(day), StoreDay(day.AddDays(1)));

    public string StoreInstant(DateTimeOffset instant) => FormatUtc(instant.UtcDateTime);

    public DateTimeOffset ReadInstant(string stored) => new(ParseUtc(stored), TimeSpan.Zero);

    public static string FormatUtc(DateTime utc) =>
        DateTime.SpecifyKind(utc, DateTimeKind.Utc).ToString(Format, CultureInfo.InvariantCulture);

    public static DateTime ParseUtc(string stored)
    {
        if (string.IsNullOrWhiteSpace(stored))
        {
            throw new PersistenceException("A stored instant is missing.");
        }

        if (!DateTime.TryParseExact(
                stored.Trim(),
                Format,
                CultureInfo.InvariantCulture,
                DateTimeStyles.AssumeUniversal | DateTimeStyles.AdjustToUniversal,
                out var utc))
        {
            throw new PersistenceException($"A stored instant is not ISO-8601 UTC: {stored}");
        }

        return DateTime.SpecifyKind(utc, DateTimeKind.Utc);
    }

    /// Invalid local midnights move forward to the next valid minute.
    /// Ambiguous midnights use the earlier instant.
    public static DateTime ToUtc(DateTime unspecifiedLocal, TimeZoneInfo zone)
    {
        var local = DateTime.SpecifyKind(unspecifiedLocal, DateTimeKind.Unspecified);
        if (zone.IsInvalidTime(local))
        {
            var adjusted = local;
            while (zone.IsInvalidTime(adjusted))
            {
                adjusted = adjusted.AddMinutes(1);
            }

            return TimeZoneInfo.ConvertTimeToUtc(adjusted, zone);
        }

        if (zone.IsAmbiguousTime(local))
        {
            var offset = zone.GetAmbiguousTimeOffsets(local).Max();
            return new DateTimeOffset(local, offset).UtcDateTime;
        }

        return TimeZoneInfo.ConvertTimeToUtc(local, zone);
    }
}
