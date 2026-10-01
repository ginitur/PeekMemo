namespace PeekMemo.Core.Persistence;

public static class PersistenceLog
{
    public static void Error(Exception exception) =>
        System.Diagnostics.Trace.TraceError("[Persistence] {0}", exception);
}
