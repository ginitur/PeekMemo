using System.Globalization;
using System.Windows;
using System.Windows.Controls;
using PeekMemo.Core.Settings;

namespace PeekMemo.Windows.Settings;

public partial class SettingsWindow : Window
{
    static readonly double[] OpenDelays = [0, 0.10, 0.16, 0.25, 0.40];
    static readonly double[] CloseDelays = [0.15, 0.25, 0.35, 0.50, 0.75];

    readonly SettingsStore _store;
    readonly IStartupRegistration _startup;
    readonly AppSettings _settings;

    public event Action<AppSettings>? Saved;

    public SettingsWindow(SettingsStore store, AppSettings settings, IStartupRegistration startup)
    {
        InitializeComponent();
        _store = store;
        _startup = startup;
        _settings = settings;
        LaunchAtStartupBox.IsChecked = settings.LaunchAtStartup;
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
        PanelSizeText.Text = string.Format(
            CultureInfo.CurrentCulture,
            "Panel size: {0:0} × {1:0} DIP",
            settings.PanelWidth,
            settings.PanelHeight);
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
        _settings.LaunchAtStartup = LaunchAtStartupBox.IsChecked == true;
        _settings.Theme = ThemeBox.SelectedIndex switch
        {
            1 => ThemePreference.Light.ToString(),
            2 => ThemePreference.Dark.ToString(),
            _ => ThemePreference.System.ToString()
        };
        _settings.PanelOpacity = OpacitySlider.Value;
        _settings.WedgeThickness = ThicknessSlider.Value;
        _settings.WedgeLength = LengthSlider.Value;
        _settings.WedgeOpacity = WedgeOpacitySlider.Value;
        _settings.HoverOpenDelaySeconds = SelectedDelay(OpenDelayBox, _settings.HoverOpenDelaySeconds);
        _settings.HoverCloseDelaySeconds = SelectedDelay(CloseDelayBox, _settings.HoverCloseDelaySeconds);
        _settings.ReduceMotion = ReduceMotionBox.IsChecked == true;
        _store.Save(_settings);
        _startup.Apply(_settings.LaunchAtStartup, Environment.ProcessPath ?? "");
        Saved?.Invoke(_settings);
        Close();
    }

    void Cancel_Click(object sender, RoutedEventArgs e) => Close();

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
