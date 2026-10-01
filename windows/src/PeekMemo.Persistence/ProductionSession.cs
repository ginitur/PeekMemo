using PeekMemo.Core.Daily;
using PeekMemo.Core.Interaction;

namespace PeekMemo.Persistence;

/// Loads the real database. Sample rows are never inserted here.
public static class ProductionSession
{
    public static DailySession Open(MemoDatabase database, DateOnly today, PanelInteraction interaction)
    {
        var board = new MemoBoard(today);
        board.Load(database.Categories.ListAll(), database.Memos.ListAll());
        board.Store = new SqliteBoardStore(database);
        return new DailySession(board, interaction);
    }
}
