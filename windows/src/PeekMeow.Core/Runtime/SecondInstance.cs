using System.Text.Json;

namespace PeekMeow.Core.Runtime;

/// Identity written by the first process. A second process uses it instead of guessing from the window.
public sealed record RunningInstance(int Pid, string Version, string Commit, string Path);

public static class SecondInstance
{
    public static bool ShouldSignalExisting(string launchedVersion, RunningInstance? running, bool processIsLive)
    {
        return processIsLive
            && running is not null
            && !string.IsNullOrWhiteSpace(running.Version)
            && string.Equals(running.Version, launchedVersion, StringComparison.Ordinal);
    }

    public static string RefusalMessage(
        string launchedVersion,
        string launchedPath,
        RunningInstance? running,
        bool processIsLive)
    {
        if (processIsLive
            && running is not null
            && !string.IsNullOrWhiteSpace(running.Version)
            && !string.Equals(running.Version, launchedVersion, StringComparison.Ordinal))
        {
            return "A different version of PeekMeow is already running.\n"
                + "Quit the existing PeekMeow before launching this version.\n\n"
                + "Running:\n"
                + running.Version + "\n"
                + running.Path + "\n\n"
                + "Launched:\n"
                + launchedVersion + "\n"
                + launchedPath;
        }

        return "PeekMeow is already running.\n"
            + "Quit it from the tray before launching this copy.\n\n"
            + "Launched:\n"
            + launchedVersion + "\n"
            + launchedPath;
    }
}

public static class InstanceRecord
{
    public static void Write(string path, RunningInstance instance)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(path);
        var directory = System.IO.Path.GetDirectoryName(path);
        if (!string.IsNullOrEmpty(directory))
        {
            Directory.CreateDirectory(directory);
        }

        var json = JsonSerializer.Serialize(instance);
        var temporary = path + ".tmp";
        File.WriteAllText(temporary, json);
        File.Move(temporary, path, overwrite: true);
    }

    public static RunningInstance? TryRead(string path)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(path) || !File.Exists(path))
            {
                return null;
            }

            return JsonSerializer.Deserialize<RunningInstance>(File.ReadAllText(path));
        }
        catch (Exception exception) when (exception is IOException or JsonException or UnauthorizedAccessException)
        {
            return null;
        }
    }
}
