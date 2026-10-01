namespace PeekMeow.Core.Geometry;

/// One monitor's pixel ↔ DIP boundary. Core geometry stays in DIPs after this conversion.
/// Scale is dpi/96. A missing DPI (0) is treated as 96 so a failed query does not collapse to zero.
public readonly record struct DpiScale(uint Dpi)
{
    public const uint Baseline = 96;

    public double Factor => (Dpi == 0 ? Baseline : Dpi) / (double)Baseline;

    public double ToDip(double pixels) => pixels / Factor;

    public int ToPixels(double dip) =>
        (int)Math.Round(dip * Factor, MidpointRounding.AwayFromZero);

    public DipRect ToDip(int left, int top, int right, int bottom) =>
        new(ToDip(left), ToDip(top), ToDip(right - left), ToDip(bottom - top));

    /// Rounds each edge, then keeps a positive size. Width and height are not left/right differences
    /// of independently rounded edges, which can drop a pixel.
    public PixelRect ToPixels(DipRect dip)
    {
        var left = ToPixels(dip.X);
        var top = ToPixels(dip.Y);
        var width = Math.Max(1, ToPixels(dip.Width));
        var height = Math.Max(1, ToPixels(dip.Height));
        return new PixelRect(left, top, left + width, top + height);
    }
}

/// Win32 rectangle in physical pixels. Right and bottom are exclusive, matching RECT.
public readonly record struct PixelRect(int Left, int Top, int Right, int Bottom)
{
    public int Width => Right - Left;
    public int Height => Bottom - Top;

    public bool Contains(int x, int y) => x >= Left && x < Right && y >= Top && y < Bottom;
}
