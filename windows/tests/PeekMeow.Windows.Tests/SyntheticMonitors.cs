using PeekMeow.Core.Geometry;

namespace PeekMeow.Windows.Tests;

/// Physical pixels. A is 100%, B is 150% to the right, C is 200% below A.
/// Working areas differ so a hard-coded taskbar height cannot pass.
static class SyntheticMonitors
{
    public static MonitorDescriptor A { get; } = MonitorDescriptor.FromPixels(
        @"\\.\DISPLAY1",
        boundsLeft: 0, boundsTop: 0, boundsRight: 1920, boundsBottom: 1080,
        workLeft: 0, workTop: 0, workRight: 1920, workBottom: 1040,
        dpi: 96,
        isPrimary: true);

    public static MonitorDescriptor B { get; } = MonitorDescriptor.FromPixels(
        @"\\.\DISPLAY2",
        boundsLeft: 1920, boundsTop: 0, boundsRight: 4480, boundsBottom: 1440,
        workLeft: 1920, workTop: 0, workRight: 4480, workBottom: 1392,
        dpi: 144,
        isPrimary: false);

    public static MonitorDescriptor C { get; } = MonitorDescriptor.FromPixels(
        @"\\.\DISPLAY3",
        boundsLeft: 0, boundsTop: 1080, boundsRight: 3840, boundsBottom: 3240,
        workLeft: 0, workTop: 1160, workRight: 3780, workBottom: 3240,
        dpi: 192,
        isPrimary: false);

    public static IReadOnlyList<MonitorDescriptor> All { get; } = [A, B, C];
}
