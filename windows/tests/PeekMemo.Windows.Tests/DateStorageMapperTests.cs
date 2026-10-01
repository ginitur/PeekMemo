using PeekMemo.Persistence;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class DateStorageMapperTests
{
    [Fact]
    public void LocalMidnightIsStoredAsAFixedUtcInstant()
    {
        var mapper = new DateStorageMapper(PersistenceTestSupport.Zone);
        var stored = mapper.StoreDay(PersistenceTestSupport.Today);
        var (start, next) = mapper.DayRange(PersistenceTestSupport.Today);

        Assert.Equal("2026-10-01T07:00:00.000Z", stored);
        Assert.Equal(stored, start);
        Assert.Equal("2026-10-02T07:00:00.000Z", next);
        Assert.Equal(PersistenceTestSupport.Today, mapper.ReadDay(stored));
        Assert.Equal(
            "2026-10-01T15:00:00.000Z",
            mapper.StoreInstant(PersistenceTestSupport.At));
        Assert.Equal(PersistenceTestSupport.At, mapper.ReadInstant(mapper.StoreInstant(PersistenceTestSupport.At)));
    }

    [Fact]
    public void DailySqlUsesAHalfOpenRangeAndDoesNotCallDate()
    {
        Assert.Contains("scheduled_date >= @start", MemoSql.DailyItems, StringComparison.Ordinal);
        Assert.Contains("scheduled_date < @next", MemoSql.DailyItems, StringComparison.Ordinal);
        Assert.DoesNotContain("DATE(", MemoSql.DailyItems, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("DATE(", MemoSql.PastUnfinished, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("DATE(", MemoSql.NextRootOrder, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("scheduled_date < @start", MemoSql.PastUnfinished, StringComparison.Ordinal);
    }
}
