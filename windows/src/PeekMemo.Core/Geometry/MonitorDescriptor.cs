namespace PeekMemo.Core.Geometry;

/// Stable monitor identity plus both pixel and DIP rectangles.
/// Pick a monitor from <see cref="PixelBounds"/>. DIP rectangles of mixed-DPI monitors overlap
/// and are not a hit-test space.
public readonly record struct MonitorDescriptor(
    string DeviceName,
    PixelRect PixelBounds,
    PixelRect PixelWorkingArea,
    uint Dpi,
    bool IsPrimary)
{
    public DpiScale Scale => new(Dpi);

    public DipRect Bounds => Scale.ToDip(PixelBounds.Left, PixelBounds.Top, PixelBounds.Right, PixelBounds.Bottom);

    public DipRect WorkingArea => Scale.ToDip(
        PixelWorkingArea.Left,
        PixelWorkingArea.Top,
        PixelWorkingArea.Right,
        PixelWorkingArea.Bottom);

    public static MonitorDescriptor FromPixels(
        string deviceName,
        int boundsLeft,
        int boundsTop,
        int boundsRight,
        int boundsBottom,
        int workLeft,
        int workTop,
        int workRight,
        int workBottom,
        uint dpi,
        bool isPrimary) =>
        new(
            deviceName,
            new PixelRect(boundsLeft, boundsTop, boundsRight, boundsBottom),
            new PixelRect(workLeft, workTop, workRight, workBottom),
            dpi,
            isPrimary);

    /// Pixel hit test. Does not fall back to a DIP rectangle.
    public static bool TryContaining(
        IReadOnlyList<MonitorDescriptor> monitors,
        int pixelX,
        int pixelY,
        out MonitorDescriptor monitor)
    {
        foreach (var candidate in monitors)
        {
            if (candidate.PixelBounds.Contains(pixelX, pixelY))
            {
                monitor = candidate;
                return true;
            }
        }

        monitor = default;
        return false;
    }
}
