using PeekMemo.Core.Geometry;
using PeekMemo.Core.Layout;
using PeekMemo.Core.Models;
using PeekMemo.Core.Persistence;
using PeekMemo.Core.Settings;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class SettingsPersistenceTests
{
    [Fact]
    public void SettingsRoundTripAndRestartFromATempDirectory()
    {
        var directory = Path.Combine(Path.GetTempPath(), "peekmemo-tests", Guid.NewGuid().ToString("N"));
        try
        {
            var store = new SettingsStore(directory);
            var saved = new AppSettings
            {
                Edge = ScreenEdge.Bottom.ToString(),
                EdgeOffset = 180,
                MonitorDeviceName = @"\\.\DISPLAY2",
                PanelWidth = 360,
                PanelHeight = 500,
                PanelOpacity = 0.8,
                Theme = ThemePreference.Dark.ToString(),
                HoverOpenDelaySeconds = 0.25,
                HoverCloseDelaySeconds = 0.5,
                ReduceMotion = true,
                LaunchAtStartup = true,
                WedgeThickness = 4,
                WedgeLength = 72,
                WedgeOpacity = 0.7
            };

            store.Save(saved);
            var loaded = new SettingsStore(directory).Load();

            Assert.StartsWith(Path.GetTempPath(), store.FilePath, StringComparison.OrdinalIgnoreCase);
            Assert.DoesNotContain("PeekMemo.sqlite", store.FilePath, StringComparison.OrdinalIgnoreCase);
            Assert.Equal(ScreenEdge.Bottom, loaded.ResolvedEdge());
            Assert.Equal(180d, loaded.EdgeOffset.GetValueOrDefault());
            Assert.Equal(@"\\.\DISPLAY2", loaded.MonitorDeviceName);
            Assert.Equal(360d, loaded.PanelWidth);
            Assert.Equal(500d, loaded.PanelHeight);
            Assert.Equal(ThemePreference.Dark, loaded.ResolvedTheme());
            Assert.True(loaded.ReduceMotion);
            Assert.True(loaded.LaunchAtStartup);
            Assert.Equal(saved.HoverOpenDelaySeconds, loaded.HoverOpenDelaySeconds);
        }
        finally
        {
            if (Directory.Exists(directory))
            {
                Directory.Delete(directory, recursive: true);
            }
        }
    }

    [Fact]
    public void StoredTopAndCorruptJsonFallBackWithoutDeletingTheFile()
    {
        var directory = Path.Combine(Path.GetTempPath(), "peekmemo-tests", Guid.NewGuid().ToString("N"));
        try
        {
            var store = new SettingsStore(directory);
            store.Save(new AppSettings { Edge = ScreenEdge.Top.ToString() });
            Assert.Equal(ScreenEdge.Right, store.Load().ResolvedEdge());

            File.WriteAllText(store.FilePath, "{ not json");
            var fallback = store.Load();
            Assert.Equal(ScreenEdge.Right, fallback.ResolvedEdge());
            Assert.Equal(PanelSize.DefaultWidth, fallback.PanelWidth, precision: 0);
            Assert.True(File.Exists(store.FilePath));
        }
        finally
        {
            if (Directory.Exists(directory))
            {
                Directory.Delete(directory, recursive: true);
            }
        }
    }

    [Fact]
    public void NestedPlacementWinsAndStillRoundTripsWithTheFlatFields()
    {
        var directory = Path.Combine(Path.GetTempPath(), "peekmemo-tests", Guid.NewGuid().ToString("N"));
        try
        {
            var store = new SettingsStore(directory);
            var settings = new AppSettings
            {
                Edge = ScreenEdge.Right.ToString(),
                EdgeOffset = 10,
                MonitorDeviceName = @"\\.\DISPLAY1"
            };
            settings.Placement = new PlacementSettings
            {
                Monitor = @"\\.\DISPLAY2",
                Edge = ScreenEdge.Bottom.ToString(),
                Offset = 250
            };
            settings.WritePanelSize(100, 9000);

            var work = new DipRect(0, 0, 2000, 1000);
            var resolved = settings.ResolveAnchor(work);
            Assert.Equal(ScreenEdge.Bottom, resolved.Edge);
            Assert.Equal(250d, resolved.Offset);
            Assert.Equal(@"\\.\DISPLAY2", resolved.MonitorIdentifier);
            Assert.Equal(PanelSize.MinimumWidth, settings.PanelWidth);
            Assert.Equal(PanelSize.AbsoluteMaximum, settings.PanelHeight);

            store.Save(settings);
            var json = File.ReadAllText(store.FilePath);
            Assert.Contains("\"placement\"", json, StringComparison.Ordinal);
            Assert.Contains("\"monitor\"", json, StringComparison.Ordinal);
            Assert.DoesNotContain("\"x\"", json, StringComparison.OrdinalIgnoreCase);
            Assert.DoesNotContain("\"y\"", json, StringComparison.OrdinalIgnoreCase);
            Assert.False(File.Exists(store.FilePath + ".tmp"));

            var loaded = new SettingsStore(directory).Load();
            var anchor = loaded.ResolveAnchor(work);
            Assert.Equal(ScreenEdge.Bottom, anchor.Edge);
            Assert.Equal(250d, anchor.Offset);
            Assert.Equal(@"\\.\DISPLAY2", anchor.MonitorIdentifier);
            Assert.Equal(PanelSize.MinimumWidth, loaded.PanelWidth);
        }
        finally
        {
            if (Directory.Exists(directory))
            {
                Directory.Delete(directory, recursive: true);
            }
        }
    }

    [Fact]
    public void APhase1FileWithoutPlacementStillResolvesAndANullOffsetCenters()
    {
        var work = new DipRect(0, 0, 800, 600);
        var flat = new AppSettings
        {
            Edge = ScreenEdge.Left.ToString(),
            EdgeOffset = 80,
            MonitorDeviceName = @"\\.\DISPLAY1"
        };
        var anchor = flat.ResolveAnchor(work);
        Assert.Equal(ScreenEdge.Left, anchor.Edge);
        Assert.Equal(80d, anchor.Offset);

        var centered = new AppSettings().ResolveAnchor(work);
        Assert.Equal(ScreenEdge.Right, centered.Edge);
        Assert.Equal(work.Height / 2, centered.Offset);

        var storedTop = new AppSettings
        {
            Placement = new PlacementSettings { Edge = ScreenEdge.Top.ToString(), Offset = 12, Monitor = "m" }
        };
        Assert.Equal(ScreenEdge.Right, storedTop.ResolveAnchor(work).Edge);
    }

    [Fact]
    public void SettingsDoNotStoreAbsoluteCoordinates()
    {
        var names = typeof(AppSettings).GetProperties().Select(property => property.Name).ToHashSet(StringComparer.Ordinal);
        Assert.DoesNotContain("X", names);
        Assert.DoesNotContain("Y", names);
        Assert.DoesNotContain("Left", names);
        Assert.DoesNotContain("Top", names);
        Assert.Contains("Edge", names);
        Assert.Contains("EdgeOffset", names);
        Assert.Contains("MonitorDeviceName", names);
    }

    [Fact]
    public void PanelSizeFloorIs280By300()
    {
        var clamped = PanelSize.ClampStored(100, 100);
        Assert.Equal(280d, clamped.Width);
        Assert.Equal(300d, clamped.Height);
        Assert.Equal(340d, PanelSize.DefaultWidth);
        Assert.Equal(460d, PanelSize.DefaultHeight);
    }

    [Fact]
    public void DefaultDataRootIsUnderLocalAppData()
    {
        var root = AppPaths.DefaultRoot();
        Assert.EndsWith("PeekMemo", root, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("PeekMemo", AppPaths.DatabaseFile(root), StringComparison.Ordinal);
        Assert.EndsWith(Path.Combine("PeekMemo", "Backgrounds"), AppPaths.BackgroundsDirectory(root), StringComparison.OrdinalIgnoreCase);
        Assert.False(Directory.Exists(Path.Combine(root, "this-test-must-not-create-a-folder")));
    }

    [Fact]
    public void StartupRegistrationIsPerUser()
    {
        Assert.Equal("PeekMemo", StartupRegistration.ValueName);
        Assert.StartsWith("Software\\Microsoft\\Windows\\CurrentVersion\\Run", StartupRegistration.RunKeyPath, StringComparison.Ordinal);
        Assert.DoesNotContain("HKLM", StartupRegistration.RunKeyPath, StringComparison.OrdinalIgnoreCase);
        Assert.Equal("\"C:\\Program Files\\PeekMemo\\PeekMemo.exe\"", StartupRegistration.QuoteCommand(@"C:\Program Files\PeekMemo\PeekMemo.exe"));
    }

    [Fact]
    public void SchemaMatchesTheMacColumns()
    {
        Assert.Equal(
            ["id", "name", "icon", "color", "sort_order", "is_archived", "created_at", "updated_at"],
            MemoSchema.CategoryColumns);
        Assert.Equal(
            ["id", "category_id", "parent_id", "type", "title", "body", "is_completed", "completed_at", "sort_order", "scheduled_date", "due_date", "is_archived", "created_at", "updated_at"],
            MemoSchema.MemoItemColumns);
        Assert.Equal("task", MemoTypeNames.Task);
        Assert.Equal("note", MemoTypeNames.Note);
    }

    [Fact]
    public void EntityIdsUseUppercaseUuidText()
    {
        var id = Guid.Parse("12345678-9abc-def0-1234-56789abcdef0");
        var text = EntityId.Format(id);

        Assert.Equal("12345678-9ABC-DEF0-1234-56789ABCDEF0", text);
        Assert.Equal(id, EntityId.Parse(text));
        Assert.Equal(id, EntityId.Parse(text.ToLowerInvariant()));
    }
}
