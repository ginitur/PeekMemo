namespace PeekMeow.Core.Geometry;

/// Device-independent rectangle. Origin is the top-left. Y grows downward (WPF / Win32).
public readonly record struct DipRect(double X, double Y, double Width, double Height)
{
    public double Right => X + Width;
    public double Bottom => Y + Height;

    public bool Contains(DipRect inner) =>
        inner.X >= X - 0.01
        && inner.Y >= Y - 0.01
        && inner.Right <= Right + 0.01
        && inner.Bottom <= Bottom + 0.01;

    public bool ContainsPoint(double x, double y) =>
        x >= X && x < Right && y >= Y && y < Bottom;
}

public readonly record struct DipPoint(double X, double Y);
