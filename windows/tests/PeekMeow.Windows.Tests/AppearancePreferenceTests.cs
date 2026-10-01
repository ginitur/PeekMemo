using PeekMeow.Core.Layout;
using PeekMeow.Core.Settings;
using Xunit;

namespace PeekMeow.Windows.Tests;

public class AppearancePreferenceTests
{
    [Fact]
    public void SettingsKeepSizeAndBackgroundAcrossANewStore()
    {
        var root = PersistenceTestSupport.NewRoot();
        try
        {
            var saved = new AppSettings
            {
                PanelWidth = 420,
                PanelHeight = 640,
                PanelOpacity = 0.82,
                BackgroundMode = PanelBackgroundMode.Image.ToString(),
                BackgroundSolidColor = "#112233",
                BackgroundSolidOpacity = 0.9,
                BackgroundImageFilename = "background-0123456789abcdef0123456789abcdef.png",
                BackgroundImageContentMode = BackgroundFit.Fit.ToString(),
                BackgroundImagePosition = BackgroundAnchor.Bottom.ToString(),
                BackgroundImageOpacity = 0.4,
                BackgroundOverlayOpacity = 0.3,
                WedgeColor = "#445566"
            };
            new SettingsStore(root).Save(saved);

            var loaded = new SettingsStore(root).Load();
            Assert.Equal(420d, loaded.PanelWidth);
            Assert.Equal(640d, loaded.PanelHeight);
            Assert.Equal(PanelBackgroundMode.Image, loaded.ResolvedBackgroundMode());
            Assert.Equal(BackgroundFit.Fit, loaded.ResolvedBackgroundFit());
            Assert.Equal(BackgroundAnchor.Bottom, loaded.ResolvedBackgroundPosition());
            Assert.Equal(saved.BackgroundImageFilename, loaded.ResolvedBackgroundFilename());
            Assert.Equal("#445566", loaded.ResolvedWedgeColor());
            Assert.Equal(0.4, loaded.BackgroundImageOpacity);
            Assert.Equal(0.3, loaded.BackgroundOverlayOpacity);
            Assert.Equal(PanelSize.ClampStored(420, 640).Width, loaded.PanelWidth);
        }
        finally
        {
            PersistenceTestSupport.Delete(root);
        }
    }

    [Fact]
    public void UnknownAppearanceValuesFallBackWithoutStretching()
    {
        var settings = new AppSettings
        {
            BackgroundMode = "nope",
            BackgroundImageContentMode = "stretch",
            BackgroundImagePosition = "left",
            BackgroundImageFilename = "../secret.png",
            WedgeColor = "blue",
            PanelOpacity = 4
        };

        Assert.Equal(PanelBackgroundMode.Default, settings.ResolvedBackgroundMode());
        Assert.Equal(BackgroundFit.Fill, settings.ResolvedBackgroundFit());
        Assert.Equal(BackgroundAnchor.Center, settings.ResolvedBackgroundPosition());
        Assert.Null(settings.ResolvedBackgroundFilename());
        Assert.Null(settings.ResolvedWedgeColor());
        Assert.Equal(1, AppearanceLimits.PanelOpacity(settings.PanelOpacity));
        Assert.Equal(BackgroundStretch.UniformToFill, BackgroundLayout.StretchFor(BackgroundFit.Fill));
        Assert.Equal(BackgroundStretch.Uniform, BackgroundLayout.StretchFor(BackgroundFit.Fit));
        Assert.DoesNotContain(Enum.GetNames<BackgroundStretch>(), name => name.Equals("Fill", StringComparison.Ordinal));
    }

    [Fact]
    public void PicturesAreCopiedIntoTheBackgroundFolder()
    {
        var root = PersistenceTestSupport.NewRoot();
        try
        {
            var source = Path.Combine(root, "camera.png");
            File.WriteAllBytes(source, Convert.FromBase64String(
                "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="));
            File.WriteAllBytes(Path.Combine(root, "shot.jpg"), [0xFF, 0xD8, 0xFF, 0x00]);
            File.WriteAllBytes(Path.Combine(root, "shot.bmp"), [0x42, 0x4D, 0x00, 0x00]);
            var webp = new byte[12];
            webp[0] = (byte)'R';
            webp[1] = (byte)'I';
            webp[2] = (byte)'F';
            webp[3] = (byte)'F';
            webp[8] = (byte)'W';
            webp[9] = (byte)'E';
            webp[10] = (byte)'B';
            webp[11] = (byte)'P';
            File.WriteAllBytes(Path.Combine(root, "shot.webp"), webp);
            File.WriteAllBytes(Path.Combine(root, "shot.heic"), [0x00, 0x00, 0x00, 0x18]);

            var store = new BackgroundImageStore(AppPaths.BackgroundsDirectory(root));
            var filename = store.Install(source);
            Assert.True(BackgroundImageStore.IsSafeFilename(filename));
            Assert.EndsWith(".png", filename, StringComparison.Ordinal);
            var copied = store.ExistingFile(filename);
            Assert.NotNull(copied);
            Assert.NotEqual(Path.GetFullPath(source), Path.GetFullPath(copied));
            Assert.StartsWith(Path.GetFullPath(store.DirectoryPath), Path.GetFullPath(copied), StringComparison.Ordinal);
            Assert.True(File.Exists(source));
            Assert.NotNull(store.Install(Path.Combine(root, "shot.jpg")));
            Assert.NotNull(store.Install(Path.Combine(root, "shot.bmp")));
            Assert.NotNull(store.Install(Path.Combine(root, "shot.webp")));
            Assert.Throws<BackgroundImageException>(() => store.Install(Path.Combine(root, "shot.heic")));
            Assert.Null(store.ExistingFile("../PeekMeow.sqlite"));
        }
        finally
        {
            PersistenceTestSupport.Delete(root);
        }
    }

    [Fact]
    public void TheSamePictureIsNotDecodedAgain()
    {
        var cache = new DecodeCache<string>();
        Assert.Equal("pixels", cache.Get("background.png", 10, () => "pixels"));
        Assert.Equal("pixels", cache.Get("background.png", 10, () => throw new InvalidOperationException("decoded again")));
        Assert.Equal(1, cache.DecodeCount);
        Assert.Equal("new", cache.Get("background.png", 11, () => "new"));
        Assert.Equal(2, cache.DecodeCount);
    }
}
