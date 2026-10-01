using PeekMeow.Core.Runtime;
using Xunit;

namespace PeekMeow.Windows.Tests;

public class SecondInstanceTests
{
    [Fact]
    public void SameLiveVersionSignalsTheExistingProcess()
    {
        var running = new RunningInstance(7, "0.1.0-rc.3", "abc", @"C:\Temp\PeekMeow-rc3\PeekMeow.exe");
        Assert.True(SecondInstance.ShouldSignalExisting("0.1.0-rc.3", running, processIsLive: true));
    }

    [Fact]
    public void DifferentVersionRefusesWithoutSignaling()
    {
        var running = new RunningInstance(7, "0.1.0-rc.1", "old", @"C:\Temp\PeekMeow-rc1\PeekMeow.exe");
        Assert.False(SecondInstance.ShouldSignalExisting("0.1.0-rc.3", running, processIsLive: true));
        var message = SecondInstance.RefusalMessage(
            "0.1.0-rc.3",
            @"C:\Temp\PeekMeow-rc3\PeekMeow.exe",
            running,
            processIsLive: true);
        Assert.Contains("A different version of PeekMeow is already running.", message);
        Assert.Contains("Quit the existing PeekMeow before launching this version.", message);
        Assert.Contains("Running:\n0.1.0-rc.1", message);
        Assert.Contains("Launched:\n0.1.0-rc.3", message);
    }

    [Fact]
    public void UnknownOrDeadProcessDoesNotSignal()
    {
        var stale = new RunningInstance(7, "0.1.0-rc.3", "abc", @"C:\Temp\PeekMeow-rc3\PeekMeow.exe");
        Assert.False(SecondInstance.ShouldSignalExisting("0.1.0-rc.3", null, processIsLive: false));
        Assert.False(SecondInstance.ShouldSignalExisting("0.1.0-rc.3", stale, processIsLive: false));
        var message = SecondInstance.RefusalMessage(
            "0.1.0-rc.3",
            @"C:\Temp\PeekMeow-rc3\PeekMeow.exe",
            null,
            processIsLive: false);
        Assert.Contains("PeekMeow is already running.", message);
        Assert.Contains("Quit it from the tray before launching this copy.", message);
        Assert.Contains("Launched:\n0.1.0-rc.3", message);
        Assert.DoesNotContain("A different version", message);
    }

    [Fact]
    public void InstanceFileRoundTrips()
    {
        var directory = Path.Combine(Path.GetTempPath(), "peekmeow-instance-test", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(directory);
        try
        {
            var path = Path.Combine(directory, "instance.json");
            var instance = new RunningInstance(42, "0.1.0-rc.3", "deadbeef", @"C:\Temp\PeekMeow-rc3\PeekMeow.exe");
            InstanceRecord.Write(path, instance);
            Assert.Equal(instance, InstanceRecord.TryRead(path));
            File.WriteAllText(path, "{not json");
            Assert.Null(InstanceRecord.TryRead(path));
        }
        finally
        {
            Directory.Delete(directory, recursive: true);
        }
    }
}
