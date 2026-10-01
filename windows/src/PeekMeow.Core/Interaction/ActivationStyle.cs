namespace PeekMeow.Core.Interaction;

/// Win32 extended-style bits for peek vs typing.
/// Changing them must not move, resize, or reorder the panel.
public static class ActivationStyle
{
    public const long ToolWindow = 0x00000080;
    public const long NoActivate = 0x08000000;

    public const uint NoMove = 0x0001;
    public const uint NoSize = 0x0002;
    public const uint NoZOrder = 0x0004;
    public const uint NoActivatePosition = 0x0010;
    public const uint FrameChanged = 0x0020;

    public const uint FrameStable = NoMove | NoSize | NoZOrder | NoActivatePosition | FrameChanged;

    public static long ForMode(long current, bool peek)
    {
        var style = current | ToolWindow;
        return peek ? style | NoActivate : style & ~NoActivate;
    }
}
