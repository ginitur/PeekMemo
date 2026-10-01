using PeekMemo.Core.Settings;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class AppearancePreviewTests
{
    [Fact]
    public void PreviewCopiesAppearanceAndCancelRestoresWithoutWritingPlacement()
    {
        var directory = Path.Combine(Path.GetTempPath(), "peekmemo-tests", Guid.NewGuid().ToString("N"));
        try
        {
            var store = new SettingsStore(directory);
            var live = new AppSettings
            {
                Edge = "Left",
                EdgeOffset = 40,
                PanelOpacity = 0.94,
                WedgeOpacity = 0.55,
                BackgroundImageOpacity = 0.6
            };
            var baseline = SettingsStore.Clone(live);
            var preview = SettingsStore.Clone(live);
            preview.PanelOpacity = 0.72;
            preview.WedgeOpacity = 0.3;
            preview.BackgroundImageOpacity = 0.4;
            preview.Edge = "Bottom";
            preview.EdgeOffset = 9;

            live.CopyAppearanceFrom(preview);
            Assert.Equal(0.72, live.PanelOpacity);
            Assert.Equal(0.3, live.WedgeOpacity);
            Assert.Equal(0.4, live.BackgroundImageOpacity);
            Assert.Equal("Left", live.Edge);
            Assert.Equal(40, live.EdgeOffset);
            Assert.False(File.Exists(store.FilePath));

            live.CopyAppearanceFrom(baseline);
            Assert.Equal(0.94, live.PanelOpacity);
            Assert.Equal(0.55, live.WedgeOpacity);
            Assert.Equal("Left", live.Edge);
            Assert.False(File.Exists(store.FilePath));
        }
        finally
        {
            if (Directory.Exists(directory))
            {
                Directory.Delete(directory, recursive: true);
            }
        }
    }
}
