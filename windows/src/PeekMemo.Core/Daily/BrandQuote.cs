namespace PeekMemo.Core.Daily;

/// One quiet line under Add Task. The wording is fixed and is not translated.
public static class BrandQuote
{
    public const string Text = "Toutes les grandes personnes ont d’abord été des enfants. Mais peu d’entre elles s’en souviennent.";

    /// Below this panel height the quote hides so tasks keep the space.
    public const double MinimumPanelHeight = 350;

    public static bool IsVisible(double panelHeight) => panelHeight >= MinimumPanelHeight;
}
