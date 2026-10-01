namespace PeekMeow.Core.Interaction;

/// The category window is already topmost. Another HWND_TOPMOST on the panel covers it.
public static class PanelZOrder
{
    public static bool PreserveOrder(bool categoryWindowOpen) => categoryWindowOpen;
}
