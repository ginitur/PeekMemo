using PeekMemo.Core.Interaction;
using PeekMemo.Core.Models;
using PeekMemo.Persistence;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class RestartPersistenceTests
{
    [Fact]
    public void ClosingTheDatabaseAndOpeningANewSessionRestoresTheFixture()
    {
        var root = PersistenceTestSupport.NewRoot();
        try
        {
            Guid workId;
            Guid personalId;
            using (var database = PersistenceTestSupport.Open(root))
            {
                var work = database.Categories.ListActive().Single(category => category.Name == "Work");
                var personal = database.Categories.ListActive().Single(category => category.Name == "Personal");
                workId = work.Id;
                personalId = personal.Id;
                var report = database.Memos.CreateTask("Prepare report", PersistenceTestSupport.Today, work.Id);
                var collect = database.Memos.CreateSubtask(report.Id, "Collect data");
                database.Memos.CreateSubtask(report.Id, "Write draft");
                database.Memos.SetCompleted(collect.Id, true, PersistenceTestSupport.At);
                database.Memos.CreateTask("Buy ink", PersistenceTestSupport.Today, personal.Id);
                database.Memos.CreateNote("Loose note", PersistenceTestSupport.Today, null);
                database.Memos.CreateTask("Finish leftover", PersistenceTestSupport.Today.AddDays(-1), work.Id);
            }

            using (var reopened = PersistenceTestSupport.Open(root))
            {
                var session = ProductionSession.Open(reopened, PersistenceTestSupport.Today, new PanelInteraction());
                var board = session.Board;

                Assert.Equal(["Personal", "Work"], board.ActiveCategories.Select(category => category.Name).OrderBy(name => name).ToArray());
                var reportAgain = board.Items.Single(item => item.Title == "Prepare report");
                Assert.False(reportAgain.IsCompleted);
                Assert.Equal(workId, reportAgain.CategoryId);
                var children = board.Items.Where(item => item.ParentId == reportAgain.Id).OrderBy(item => item.SortOrder).ToList();
                Assert.Equal("Collect data", children[0].Title);
                Assert.True(children[0].IsCompleted);
                Assert.Equal(PersistenceTestSupport.At, children[0].CompletedAt);
                Assert.Equal("Write draft", children[1].Title);
                Assert.False(children[1].IsCompleted);

                var ink = board.Items.Single(item => item.Title == "Buy ink");
                Assert.Equal(personalId, ink.CategoryId);
                Assert.False(ink.IsCompleted);

                var note = board.Items.Single(item => item.Title == "Loose note");
                Assert.Equal(MemoItemType.Note, note.Type);
                Assert.Null(note.CategoryId);

                var past = board.PastUnfinishedItems;
                Assert.Equal("Finish leftover", Assert.Single(past).Title);
                Assert.Contains(board.DailyItems, item => item.Title == "Prepare report");
                Assert.Contains(board.DailyItems, item => item.Title == "Buy ink");
                Assert.Contains(board.DailyItems, item => item.Title == "Loose note");
                Assert.DoesNotContain(board.DailyItems, item => item.Title == "Finish leftover");

                session.BeginAddTask();
                session.SetDraft("After restart");
                Assert.False(session.SubmitKey(enter: true, control: false, escape: false, PersistenceTestSupport.At));
            }

            using var third = PersistenceTestSupport.Open(root);
            var restored = ProductionSession.Open(third, PersistenceTestSupport.Today, new PanelInteraction());
            Assert.Contains(restored.Board.Items, item => item.Title == "After restart");
            Assert.Contains(restored.Board.Items, item => item.Title == "Prepare report");
        }
        finally
        {
            PersistenceTestSupport.Delete(root);
        }
    }
}
