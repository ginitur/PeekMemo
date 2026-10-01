using PeekMeow.Core.Daily;
using PeekMeow.Core.Interaction;
using PeekMeow.Core.Models;
using PeekMeow.Core.Persistence;
using PeekMeow.Persistence;
using Xunit;

namespace PeekMeow.Windows.Tests;

public class MemoPersistenceTests
{
    [Fact]
    public void DailyQueryPastUnfinishedCategoryAndNotes()
    {
        var root = PersistenceTestSupport.NewRoot();
        try
        {
            using var database = PersistenceTestSupport.Open(root);
            var work = database.Categories.ListActive().Single(category => category.Name == "Work");
            var personal = database.Categories.ListActive().Single(category => category.Name == "Personal");
            database.Memos.CreateTask("Prepare report", PersistenceTestSupport.Today, work.Id);
            database.Memos.CreateTask("Buy ink", PersistenceTestSupport.Today, personal.Id);
            database.Memos.CreateNote("Loose note", PersistenceTestSupport.Today, null, "remember");
            database.Memos.CreateTask("Tomorrow", PersistenceTestSupport.Today.AddDays(1), work.Id);
            var yesterday = database.Memos.CreateTask("Finish leftover", PersistenceTestSupport.Today.AddDays(-1), work.Id);
            var done = database.Memos.CreateTask("Already done", PersistenceTestSupport.Today.AddDays(-1), work.Id);
            database.Memos.SetCompleted(done.Id, true, PersistenceTestSupport.At);
            database.Memos.CreateNote("Old note", PersistenceTestSupport.Today.AddDays(-1), null);

            var today = database.Memos.QueryDaily(PersistenceTestSupport.Today, null);
            Assert.Equal(["Prepare report", "Buy ink", "Loose note"], today.Select(item => item.Title).ToArray());
            Assert.Equal(MemoItemType.Note, today.Single(item => item.Title == "Loose note").Type);
            Assert.Null(today.Single(item => item.Title == "Loose note").CategoryId);

            var workOnly = database.Memos.QueryDaily(PersistenceTestSupport.Today, work.Id);
            Assert.Equal(["Prepare report"], workOnly.Select(item => item.Title).ToArray());

            var past = database.Memos.QueryPastUnfinished(PersistenceTestSupport.Today, null);
            Assert.Equal([yesterday.Id], past.Select(item => item.Id).ToArray());
            var personalPast = database.Memos.QueryPastUnfinished(PersistenceTestSupport.Today, personal.Id);
            Assert.Empty(personalPast);
        }
        finally
        {
            PersistenceTestSupport.Delete(root);
        }
    }

    [Fact]
    public void HierarchyCompletionIsRestoredAsOneFamily()
    {
        var root = PersistenceTestSupport.NewRoot();
        try
        {
            using var database = PersistenceTestSupport.Open(root);
            var work = database.Categories.ListActive().Single(category => category.Name == "Work");
            var parent = database.Memos.CreateTask("Parent", PersistenceTestSupport.Today, work.Id);
            var first = database.Memos.CreateSubtask(parent.Id, "A");
            var second = database.Memos.CreateSubtask(parent.Id, "B");

            database.Memos.SetCompleted(parent.Id, true, PersistenceTestSupport.At);
            Assert.All(database.Memos.ListAll().Where(item => item.Id == parent.Id || item.ParentId == parent.Id), item =>
            {
                Assert.True(item.IsCompleted);
                Assert.Equal(PersistenceTestSupport.At, item.CompletedAt);
            });

            database.Memos.SetCompleted(parent.Id, false, PersistenceTestSupport.At);
            Assert.False(Find(database, parent.Id).IsCompleted);
            Assert.True(Find(database, first.Id).IsCompleted);
            Assert.True(Find(database, second.Id).IsCompleted);

            database.Memos.SetCompleted(first.Id, false, PersistenceTestSupport.At);
            Assert.False(Find(database, parent.Id).IsCompleted);
            Assert.False(Find(database, first.Id).IsCompleted);
            Assert.True(Find(database, second.Id).IsCompleted);

            database.Memos.SetCompleted(first.Id, true, PersistenceTestSupport.At);
            Assert.True(Find(database, parent.Id).IsCompleted);
            Assert.True(Find(database, first.Id).IsCompleted);
        }
        finally
        {
            PersistenceTestSupport.Delete(root);
        }
    }

    [Fact]
    public void NotesAndCategoriesRoundTripAndDeleteCascades()
    {
        var root = PersistenceTestSupport.NewRoot();
        try
        {
            using var database = PersistenceTestSupport.Open(root);
            var work = database.Categories.ListActive().Single(category => category.Name == "Work");
            var note = database.Memos.CreateNote("Loose note", PersistenceTestSupport.Today, null, "body");
            database.Memos.Update(note with { Title = "Edited note", Body = "next", UpdatedAt = PersistenceTestSupport.At });
            var edited = Find(database, note.Id);
            Assert.Equal("Edited note", edited.Title);
            Assert.Equal("next", edited.Body);
            database.Memos.SetCompleted(note.Id, true, PersistenceTestSupport.At);
            Assert.False(Find(database, note.Id).IsCompleted);
            Assert.Throws<PersistenceException>(() => database.Memos.CreateSubtask(note.Id, "Nope"));

            var parent = database.Memos.CreateTask("Parent", PersistenceTestSupport.Today, work.Id);
            var child = database.Memos.CreateSubtask(parent.Id, "Child");
            database.Memos.Delete(parent.Id);
            Assert.DoesNotContain(database.Memos.ListAll(), item => item.Id == parent.Id || item.Id == child.Id);

            var kept = database.Memos.CreateTask("Kept", PersistenceTestSupport.Today, work.Id);
            database.Categories.Delete(work.Id);
            Assert.Null(Find(database, kept.Id).CategoryId);

            var created = database.Categories.Create("Errands", "folder", "#112233");
            database.Categories.Rename(created.Id, "Errand");
            database.Categories.UpdateColor(created.Id, "#ABCDEF");
            database.Categories.Archive(created.Id);
            Assert.DoesNotContain(database.Categories.ListActive(), category => category.Id == created.Id);
            var archived = database.Categories.ListAll().Single(category => category.Id == created.Id);
            Assert.True(archived.IsArchived);
            Assert.Equal("Errand", archived.Name);
            Assert.Equal("#ABCDEF", archived.Color);

            var personal = database.Categories.ListAll().Single(category => category.Name == "Personal");
            database.Categories.Reorder([personal.Id, archived.Id]);
            var ordered = database.Categories.ListAll().Where(category => category.Id == personal.Id || category.Id == archived.Id).OrderBy(category => category.SortOrder).ToList();
            Assert.Equal(personal.Id, ordered[0].Id);
            Assert.Equal(0, ordered[0].SortOrder);
            Assert.Equal(archived.Id, ordered[1].Id);
        }
        finally
        {
            PersistenceTestSupport.Delete(root);
        }
    }

    [Fact]
    public void ProductionSessionDoesNotLoadSampleRows()
    {
        var root = PersistenceTestSupport.NewRoot();
        try
        {
            using var database = PersistenceTestSupport.Open(root);
            var session = ProductionSession.Open(database, PersistenceTestSupport.Today, new PanelInteraction());
            Assert.Equal(2, session.Board.ActiveCategories.Count);
            Assert.Empty(session.Board.Items);
            Assert.DoesNotContain(session.Board.Items, item => item.Title == "Prepare report");
        }
        finally
        {
            PersistenceTestSupport.Delete(root);
        }
    }

    [Fact]
    public void FailedWriteRestoresTheBoard()
    {
        var board = new MemoBoard(PersistenceTestSupport.Today, PersistenceTestSupport.At);
        board.Store = new ThrowingStore();
        Assert.False(board.TryAddTask("Ship", out _));
        Assert.Empty(board.Items);
    }

    static MemoItem Find(MemoDatabase database, Guid id) =>
        database.Memos.ListAll().Single(item => item.Id == id);

    sealed class ThrowingStore : IBoardStore
    {
        public void InsertItem(MemoItem item) => throw new InvalidOperationException("disk full");
        public void UpdateItem(MemoItem item) => throw new InvalidOperationException("disk full");
        public void DeleteItem(Guid id) => throw new InvalidOperationException("disk full");
        public void SetCompleted(Guid id, bool completed, DateTimeOffset at) => throw new InvalidOperationException("disk full");
        public void InsertCategory(Category category) => throw new InvalidOperationException("disk full");
        public void UpdateCategory(Category category) => throw new InvalidOperationException("disk full");
        public void ReorderCategories(IReadOnlyList<Guid> orderedIds) => throw new InvalidOperationException("disk full");
    }
}
