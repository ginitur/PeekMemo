namespace PeekMemo.Core.Geometry;

public static class MonitorScale
{
    /// Converts a Win32 pixel rectangle (left, top, right, bottom) into DIPs.
    public static DipRect ToDip(int left, int top, int right, int bottom, uint dpi)
    {
        if (dpi == 0)
        {
            dpi = 96;
        }

        var scale = dpi / 96.0;
        return new DipRect(
            left / scale,
            top / scale,
            (right - left) / scale,
            (bottom - top) / scale);
    }
}
