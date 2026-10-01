using System.Diagnostics;
using System.Reflection;

namespace PeekMemo.Windows.Services;

internal static class BuildIdentity
{
    public static string Version { get; } = ReadVersion();
    public static string Commit { get; } = ReadCommit();
    public static string Build { get; } = ReadBuild();

    public static string Report =>
        "PeekMemo " + Version + "\ncommit: " + Commit + "\nbuild: " + Build;

    static string ReadVersion()
    {
        var informational = Informational();
        var plus = informational.IndexOf('+');
        var version = plus >= 0 ? informational[..plus] : informational;
        return string.IsNullOrWhiteSpace(version) ? "unknown" : version.Trim();
    }

    static string ReadCommit()
    {
        var informational = Informational();
        var plus = informational.IndexOf('+');
        if (plus < 0 || plus + 1 >= informational.Length)
        {
            return "unknown";
        }

        return informational[(plus + 1)..].Trim();
    }

    static string ReadBuild()
    {
        var path = AssemblyPath();
        if (string.IsNullOrWhiteSpace(path))
        {
            return "0";
        }

        var info = FileVersionInfo.GetVersionInfo(path);
        return info.FilePrivatePart.ToString();
    }

    static string Informational()
    {
        return typeof(BuildIdentity).Assembly
            .GetCustomAttribute<AssemblyInformationalVersionAttribute>()
            ?.InformationalVersion ?? "";
    }

    static string AssemblyPath()
    {
        var location = typeof(BuildIdentity).Assembly.Location;
        if (!string.IsNullOrWhiteSpace(location))
        {
            return location;
        }

        return Environment.ProcessPath ?? "";
    }
}
