using PeekMemo.Core.Daily;
using PeekMemo.Core.Models;
using Xunit;

namespace PeekMemo.Windows.Tests;

public class CompletionAndHierarchyTests
{
    static readonly DateTimeOffset Now = new(2026, 10, 1, 12, 0, 0, TimeSpan.Zero);

    [Fact]
    public void CompletingAParentCompletesChildrenAndStaysInPlace()
    {
        var parent = MemoItem.Create(MemoItemType.Task, "Parent", Now);
        var child = MemoItem.Create(MemoItemType.Task, "Child", Now, parentId: parent.Id);
        var updated = CompletionRules.SetCompleted([parent, child], parent.Id, completed: true, Now);

        Assert.All(updated, item => Assert.True(item.IsCompleted));
        Assert.All(updated, item => Assert.Equal(Now, item.ScheduledDate));
        Assert.Equal(2, updated.Count);
    }

    [Fact]
    public void CompletingTheLastChildCompletesTheParent()
    {
        var parent = MemoItem.Create(MemoItemType.Task, "Parent", Now);
        var first = MemoItem.Create(MemoItemType.Task, "A", Now, parentId: parent.Id, isCompleted: true, completedAt: Now);
        var second = MemoItem.Create(MemoItemType.Task, "B", Now, parentId: parent.Id);
        var updated = CompletionRules.SetCompleted([parent, first, second], second.Id, completed: true, Now);

        Assert.True(updated.Single(item => item.Id == parent.Id).IsCompleted);
    }

    [Fact]
    public void UncompletingAChildReopensTheParentAndLeavesTheSibling()
    {
        var parent = MemoItem.Create(MemoItemType.Task, "Parent", Now, isCompleted: true, completedAt: Now);
        var first = MemoItem.Create(MemoItemType.Task, "A", Now, parentId: parent.Id, isCompleted: true, completedAt: Now);
        var second = MemoItem.Create(MemoItemType.Task, "B", Now, parentId: parent.Id, isCompleted: true, completedAt: Now);
        var updated = CompletionRules.SetCompleted([parent, first, second], first.Id, completed: false, Now);

        Assert.False(updated.Single(item => item.Id == parent.Id).IsCompleted);
        Assert.False(updated.Single(item => item.Id == first.Id).IsCompleted);
        Assert.True(updated.Single(item => item.Id == second.Id).IsCompleted);
    }

    [Fact]
    public void UncompletingAParentLeavesChildrenCompleted()
    {
        var parent = MemoItem.Create(MemoItemType.Task, "Parent", Now, isCompleted: true, completedAt: Now);
        var child = MemoItem.Create(MemoItemType.Task, "Child", Now, parentId: parent.Id, isCompleted: true, completedAt: Now);
        var updated = CompletionRules.SetCompleted([parent, child], parent.Id, completed: false, Now);

        Assert.False(updated.Single(item => item.Id == parent.Id).IsCompleted);
        Assert.True(updated.Single(item => item.Id == child.Id).IsCompleted);
    }

    [Fact]
    public void NotesDoNotComplete()
    {
        var note = MemoItem.Create(MemoItemType.Note, "Note", Now);
        var updated = CompletionRules.SetCompleted([note], note.Id, completed: true, Now);

        Assert.False(updated[0].IsCompleted);
        Assert.Null(updated[0].CompletedAt);
    }

    [Fact]
    public void SubtasksAreOnlyOneLevelAndNotesCannotHaveThem()
    {
        var task = MemoItem.Create(MemoItemType.Task, "Task", Now);
        var sub = MemoItem.Create(MemoItemType.Task, "Sub", Now, parentId: task.Id);
        var note = MemoItem.Create(MemoItemType.Note, "Note", Now);

        Assert.True(TaskHierarchy.CanAddSubtask(task));
        Assert.False(TaskHierarchy.CanAddSubtask(sub));
        Assert.False(TaskHierarchy.CanAddSubtask(note));
    }
}
