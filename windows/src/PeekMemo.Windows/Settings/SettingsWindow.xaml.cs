using System.Globalization;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using Microsoft.Win32;
using PeekMemo.Core.Settings;

namespace PeekMemo.Windows.Settings;

public partial class SettingsWindow : Window
{
    static readonly double[] OpenDelays = [0, 0.10, 0.16, 0.25, 0.40];
    static readonly double[] CloseDelays = [0.15, 0.25, 0.35, 0.50, 0.75];

    readonly SettingsStore _store;
    readonly IStartupRegistration _startup;
    readonly AppSettings _settings;
    readonly AppSettings _baseline;
    readonly BackgroundImageStore _backgrounds;
    string? _pendingImage;
    bool _removeImage;
    bool _ready;
    bool _saved;

    public event Action<AppSettings>? Saved;
    public event Action<AppSettings>? Preview;

    public SettingsWindow(SettingsStore store, AppSettings settings, IStartupRegistration startup)
    {
        InitializeComponent();
        if (Windowing.WindowIcons.Load() is System.Windows.Media.ImageSource icon)
        {
            Icon = icon;
        }
        _store = store;
        _startup = startup;
        _settings = settings;
        _baseline = SettingsStore.Clone(settings);
        var root = Path.GetDirectoryName(store.FilePath) ?? AppPaths.DefaultRoot();
        _backgrounds = new BackgroundImageStore(AppPaths.BackgroundsDirectory(root));
        LaunchAtStartupBox.IsChecked = settings.LaunchAtStartup;
        VersionText.Text = "Version " + PeekMemo.Windows.Services.BuildIdentity.Version;
        BuildText.Text = "Build " + PeekMemo.Windows.Services.BuildIdentity.Build;
        ThemeBox.SelectedIndex = settings.ResolvedTheme() switch
        {
            ThemePreference.Light => 1,
            ThemePreference.Dark => 2,
            _ => 0
        };
        OpacitySlider.Value = Math.Clamp(settings.PanelOpacity, 0.70, 1);
        ThicknessSlider.Value = Math.Clamp(settings.WedgeThickness, 2, 6);
        LengthSlider.Value = Math.Clamp(settings.WedgeLength, 32, 96);
        WedgeOpacitySlider.Value = Math.Clamp(settings.WedgeOpacity, 0.20, 1);
        FillDelays(OpenDelayBox, OpenDelays, settings.HoverOpenDelaySeconds);
        FillDelays(CloseDelayBox, CloseDelays, settings.HoverCloseDelaySeconds);
        ReduceMotionBox.IsChecked = settings.ReduceMotion;
        WedgeColorBox.Text = settings.WedgeColor ?? "";
        BackgroundModeBox.SelectedIndex = settings.ResolvedBackgroundMode() switch
        {
            PanelBackgroundMode.Solid => 1,
            PanelBackgroundMode.Image => 2,
            _ => 0
        };
        SolidColorBox.Text = settings.BackgroundSolidColor;
        SolidOpacitySlider.Value = AppearanceLimits.SolidOpacity(settings.BackgroundSolidOpacity);
        ImageFitBox.SelectedIndex = settings.ResolvedBackgroundFit() == BackgroundFit.Fit ? 1 : 0;
        ImagePositionBox.SelectedIndex = settings.ResolvedBackgroundPosition() switch
        {
            BackgroundAnchor.Top => 0,
            BackgroundAnchor.Bottom => 2,
            _ => 1
        };
        ImageOpacitySlider.Value = AppearanceLimits.ImageOpacity(settings.BackgroundImageOpacity);
        OverlayOpacitySlider.Value = AppearanceLimits.OverlayOpacity(settings.BackgroundOverlayOpacity);
        ImageNameText.Text = settings.ResolvedBackgroundFilename() is string name
            ? $"Picture: {name}"
            : "Picture: none";
        PanelSizeText.Text = string.Format(
            CultureInfo.CurrentCulture,
            "Panel size: {0:0} × {1:0} DIP",
            settings.PanelWidth,
            settings.PanelHeight);
        AttachPreview();
        _ready = true;
    }

    void Ok_Click(object sender, RoutedEventArgs e)
    {
        var latest = _store.Load();
        _settings.PanelWidth = latest.PanelWidth;
        _settings.PanelHeight = latest.PanelHeight;
        _settings.Edge = latest.Edge;
        _settings.EdgeOffset = latest.EdgeOffset;
        _settings.MonitorDeviceName = latest.MonitorDeviceName;
        _settings.Placement = latest.Placement;
        ApplyControls(_settings);
        if (!TryApplyPicture())
        {
            return;
        }

        _store.Save(_settings);
        _startup.Apply(_settings.LaunchAtStartup, Environment.ProcessPath ?? "");
        _saved = true;
        Saved?.Invoke(_settings);
        Close();
    }

    void Cancel_Click(object sender, RoutedEventArgs e) => Close();

    protected override void OnClosing(System.ComponentModel.CancelEventArgs e)
    {
        if (!_saved)
        {
            Preview?.Invoke(_baseline);
        }

        base.OnClosing(e);
    }

    void AttachPreview()
    {
        OpacitySlider.ValueChanged += (_, _) => PublishPreview();
        ThicknessSlider.ValueChanged += (_, _) => PublishPreview();
        LengthSlider.ValueChanged += (_, _) => PublishPreview();
        WedgeOpacitySlider.ValueChanged += (_, _) => PublishPreview();
        SolidOpacitySlider.ValueChanged += (_, _) => PublishPreview();
        ImageOpacitySlider.ValueChanged += (_, _) => PublishPreview();
        OverlayOpacitySlider.ValueChanged += (_, _) => PublishPreview();
        ThemeBox.SelectionChanged += (_, _) => PublishPreview();
        BackgroundModeBox.SelectionChanged += (_, _) => PublishPreview();
        ImageFitBox.SelectionChanged += (_, _) => PublishPreview();
        ImagePositionBox.SelectionChanged += (_, _) => PublishPreview();
        ReduceMotionBox.Checked += (_, _) => PublishPreview();
        ReduceMotionBox.Unchecked += (_, _) => PublishPreview();
        WedgeColorBox.TextChanged += (_, _) => PublishPreview();
        SolidColorBox.TextChanged += (_, _) => PublishPreview();
    }

    void PublishPreview()
    {
        if (!_ready)
        {
            return;
        }

        var draft = SettingsStore.Clone(_baseline);
        ApplyControls(draft);
        draft.BackgroundImageFilename = _baseline.BackgroundImageFilename;
        Preview?.Invoke(draft);
    }

    void ApplyControls(AppSettings settings)
    {
        settings.LaunchAtStartup = LaunchAtStartupBox.IsChecked == true;
        settings.Theme = ThemeBox.SelectedIndex switch
        {
            1 => ThemePreference.Light.ToString(),
            2 => ThemePreference.Dark.ToString(),
            _ => ThemePreference.System.ToString()
        };
        settings.PanelOpacity = OpacitySlider.Value;
        settings.WedgeThickness = ThicknessSlider.Value;
        settings.WedgeLength = LengthSlider.Value;
        settings.WedgeOpacity = WedgeOpacitySlider.Value;
        settings.HoverOpenDelaySeconds = SelectedDelay(OpenDelayBox, settings.HoverOpenDelaySeconds);
        settings.HoverCloseDelaySeconds = SelectedDelay(CloseDelayBox, settings.HoverCloseDelaySeconds);
        settings.ReduceMotion = ReduceMotionBox.IsChecked == true;
        settings.WedgeColor = string.IsNullOrWhiteSpace(WedgeColorBox.Text) ? null : WedgeColorBox.Text.Trim();
        settings.BackgroundMode = BackgroundModeBox.SelectedIndex switch
        {
            1 => PanelBackgroundMode.Solid.ToString(),
            2 => PanelBackgroundMode.Image.ToString(),
            _ => PanelBackgroundMode.Default.ToString()
        };
        settings.BackgroundSolidColor = string.IsNullOrWhiteSpace(SolidColorBox.Text)
            ? "#F6F3EC"
            : SolidColorBox.Text.Trim();
        settings.BackgroundSolidOpacity = SolidOpacitySlider.Value;
        settings.BackgroundImageContentMode = ImageFitBox.SelectedIndex == 1
            ? BackgroundFit.Fit.ToString()
            : BackgroundFit.Fill.ToString();
        settings.BackgroundImagePosition = ImagePositionBox.SelectedIndex switch
        {
            0 => BackgroundAnchor.Top.ToString(),
            2 => BackgroundAnchor.Bottom.ToString(),
            _ => BackgroundAnchor.Center.ToString()
        };
        settings.BackgroundImageOpacity = ImageOpacitySlider.Value;
        settings.BackgroundOverlayOpacity = OverlayOpacitySlider.Value;
    }

    void ChoosePicture_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new OpenFileDialog
        {
            Filter = "Pictures (PNG, JPEG, WebP, BMP)|*.png;*.jpg;*.jpeg;*.webp;*.bmp",
            CheckFileExists = true
        };
        if (dialog.ShowDialog(this) != true)
        {
            return;
        }

        _pendingImage = dialog.FileName;
        _removeImage = false;
        ImageNameText.Text = $"Picture: {Path.GetFileName(dialog.FileName)}";
    }

    void RemovePicture_Click(object sender, RoutedEventArgs e)
    {
        _pendingImage = null;
        _removeImage = true;
        ImageNameText.Text = "Picture: none";
    }

    bool TryApplyPicture()
    {
        try
        {
            if (_pendingImage is not null)
            {
                var previous = _settings.BackgroundImageFilename;
                var installed = _backgrounds.Install(_pendingImage);
                _settings.BackgroundImageFilename = installed;
                if (!string.Equals(previous, installed, StringComparison.Ordinal))
                {
                    _backgrounds.RemoveManaged(previous);
                }

                return true;
            }

            if (_removeImage)
            {
                _backgrounds.RemoveManaged(_settings.BackgroundImageFilename);
                _settings.BackgroundImageFilename = null;
            }

            return true;
        }
        catch (Exception exception) when (exception is BackgroundImageException or IOException)
        {
            MessageBox.Show(this, exception.Message, "PeekMemo", MessageBoxButton.OK, MessageBoxImage.Warning);
            return false;
        }
    }

    static void FillDelays(ComboBox box, double[] values, double selected)
    {
        foreach (var value in values)
        {
            box.Items.Add(value.ToString("0.00", CultureInfo.InvariantCulture));
        }

        var index = Array.FindIndex(values, value => Math.Abs(value - selected) < 0.001);
        box.SelectedIndex = index >= 0 ? index : 0;
    }

    static double SelectedDelay(ComboBox box, double fallback)
    {
        return box.SelectedItem is string text
            && double.TryParse(text, NumberStyles.Float, CultureInfo.InvariantCulture, out var value)
            ? value
            : fallback;
    }
}
