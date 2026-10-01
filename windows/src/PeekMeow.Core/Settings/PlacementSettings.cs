namespace PeekMeow.Core.Settings;

/// Nested placement. Monitor is a display device name, not a monitor index and not an x/y pair.
public sealed class PlacementSettings
{
    public string? Monitor { get; set; }
    public string? Edge { get; set; }
    public double? Offset { get; set; }
}
