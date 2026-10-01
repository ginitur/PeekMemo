using PeekMeow.Core.Models;

namespace PeekMeow.Core.Geometry;

/// Stable placement. Only a user drag may change <see cref="Offset"/>.
/// Left/Right offset is the anchor center measured downward from the working-area top.
/// Bottom offset is the anchor center measured rightward from the working-area left.
/// Absolute screen x/y are not the stored position.
public readonly record struct EdgeAnchor(string MonitorIdentifier, ScreenEdge Edge, double Offset)
{
    public EdgeAnchor Normalized() =>
        new(MonitorIdentifier ?? "", PlacementPolicy.SupportedOrRight(Edge), Offset);
}
