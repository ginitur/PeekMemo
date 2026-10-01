namespace PeekMeow.Core.Settings;

/// Keeps a decoded picture until the file stamp changes. Hover must not decode it again.
public sealed class DecodeCache<T> where T : class
{
    readonly Dictionary<string, (long Stamp, T Value)> _entries = new();

    public int DecodeCount { get; private set; }

    public T Get(string key, long stamp, Func<T> decode)
    {
        if (_entries.TryGetValue(key, out var existing) && existing.Stamp == stamp)
        {
            return existing.Value;
        }

        var value = decode();
        DecodeCount++;
        _entries[key] = (stamp, value);
        return value;
    }
}
