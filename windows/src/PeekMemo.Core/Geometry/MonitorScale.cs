namespace PeekMemo.Core.Geometry;

public static class MonitorScale
{
    /// Converts a Win32 pixel rectangle (left, top, right, bottom) into DIPs.
    /// The formula lives on <see cref="DpiScale"/> so callers do not mix pixels and DIPs.
    public static DipRect ToDip(int left, int top, int right, int bottom, uint dpi) =>
        new DpiScale(dpi).ToDip(left, top, right, bottom);
}
