namespace PeekMeow.Core.Models;

/// Stable text form shared with the macOS client. Swift `UUID.uuidString` is uppercase 8-4-4-4-12.
public static class EntityId
{
    public static string Format(Guid id) => id.ToString("D").ToUpperInvariant();

    public static Guid Parse(string text) => Guid.Parse(text);
}
