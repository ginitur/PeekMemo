namespace PeekMeow.Core.Models;

public enum ScreenEdge
{
    Left,
    Right,
    Top,
    Bottom
}

/// v0.1 snaps to Left, Right, and Bottom. Top stays on the enum for shared switches only.
public static class PlacementPolicy
{
    public static bool IsSupported(ScreenEdge edge) => edge != ScreenEdge.Top;

    public static ScreenEdge SupportedOrRight(ScreenEdge edge) =>
        IsSupported(edge) ? edge : ScreenEdge.Right;
}
