using System.Diagnostics;
using System.IO;
using System.Threading;
using PeekMemo.Core.Runtime;

namespace PeekMemo.Windows.Services;

internal readonly struct HandoffDecision
{
    public bool Signal { get; init; }
    public string Refusal { get; init; }
}

internal static class InstanceHandoff
{
    public static void Publish(string path, string version, string commit)
    {
        InstanceRecord.Write(
            path,
            new RunningInstance(Environment.ProcessId, version, commit, Environment.ProcessPath ?? ""));
    }

    public static void RemoveIfOurs(string path)
    {
        var current = InstanceRecord.TryRead(path);
        if (current is null || current.Pid != Environment.ProcessId)
        {
            return;
        }

        try
        {
            File.Delete(path);
        }
        catch (Exception exception) when (exception is IOException or UnauthorizedAccessException)
        {
        }
    }

    public static HandoffDecision Decide(string path, string launchedVersion)
    {
        var launchedPath = Environment.ProcessPath ?? "";
        RunningInstance? running = null;
        var live = false;
        for (var attempt = 0; attempt < 6; attempt++)
        {
            running = InstanceRecord.TryRead(path);
            live = running is not null && IsLive(running);
            if (live)
            {
                break;
            }

            Thread.Sleep(50);
        }

        if (SecondInstance.ShouldSignalExisting(launchedVersion, running, live))
        {
            return new HandoffDecision { Signal = true, Refusal = "" };
        }

        return new HandoffDecision
        {
            Signal = false,
            Refusal = SecondInstance.RefusalMessage(launchedVersion, launchedPath, running, live)
        };
    }

    static bool IsLive(RunningInstance instance)
    {
        try
        {
            using var process = Process.GetProcessById(instance.Pid);
            if (!process.ProcessName.Equals("PeekMemo", StringComparison.OrdinalIgnoreCase))
            {
                return false;
            }

            string? path = null;
            try
            {
                path = process.MainModule?.FileName;
            }
            catch (Exception exception) when (exception is InvalidOperationException or System.ComponentModel.Win32Exception)
            {
            }

            if (string.IsNullOrWhiteSpace(path) || string.IsNullOrWhiteSpace(instance.Path))
            {
                return true;
            }

            return string.Equals(path, instance.Path, StringComparison.OrdinalIgnoreCase);
        }
        catch (Exception exception) when (exception is ArgumentException or InvalidOperationException)
        {
            return false;
        }
    }
}
