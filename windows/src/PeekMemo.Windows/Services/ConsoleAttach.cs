using System.Runtime.InteropServices;
using System.Text;

namespace PeekMemo.Windows.Services;

/// WinExe has no console of its own. Write to the parent's stdout when one exists.
internal static class ConsoleAttach
{
    const int AttachParentProcess = -1;
    const int StdOutput = -11;
    const int StdError = -12;

    public static void Write(string text)
    {
        var payload = text.Replace("\r\n", "\n", StringComparison.Ordinal).Replace("\n", "\r\n", StringComparison.Ordinal);
        if (!payload.EndsWith("\r\n", StringComparison.Ordinal))
        {
            payload += "\r\n";
        }

        var bytes = Encoding.UTF8.GetBytes(payload);
        WriteHandle(StdOutput, bytes);
        WriteHandle(StdError, bytes);
    }

    static void WriteHandle(int kind, byte[] bytes)
    {
        var handle = GetStdHandle(kind);
        if (!Valid(handle))
        {
            AttachConsole(AttachParentProcess);
            handle = GetStdHandle(kind);
        }

        if (!Valid(handle))
        {
            return;
        }

        WriteFile(handle, bytes, (uint)bytes.Length, out _, IntPtr.Zero);
    }

    static bool Valid(IntPtr handle) => handle != IntPtr.Zero && handle != new IntPtr(-1);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool AttachConsole(int dwProcessId);

    [DllImport("kernel32.dll")]
    static extern IntPtr GetStdHandle(int nStdHandle);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool WriteFile(IntPtr handle, byte[] bytes, uint count, out uint written, IntPtr overlapped);
}
