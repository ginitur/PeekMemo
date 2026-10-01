using PeekMeow.Core.Daily;
using PeekMeow.Core.Models;
using Xunit;

namespace PeekMeow.Windows.Tests;

public class CompletionAndHierarchyTests
{
    static readonly DateOnly Day = new(2026, 10, 1);
    static readonly DateTimeOffset Now = new(2026, 10, 1, 12, 0, 0, TimeSpan.Zero);

    [Fact]
    public void CompletingAParentCompletesChildrenAndStaysInPlace()
    {
        var parent = MemoItem.Create(MemoItemType.Task, "Parent", Day);
        var child = MemoItem.Create(MemoItemType.Task, "Child", Day, parentId: parent.Id);
        var updated = CompletionRules.SetCompleted([parent, child], parent.Id, completed: true, Now);

        Assert.All(updated, item => Assert.True(item.IsCompleted));
        Assert.All(updated, item => Assert.Equal(Day, item.ScheduledDate));
        Assert.Equal(2, updated.Count);
    }

    [Fact]
    public void CompletingTheLastChildCompletesTheParent()
    {
        var parent = MemoItem.Create(MemoItemType.Task, "Parent", Day);
        var first = MemoItem.Create(MemoItemType.Task, "A", Day, parentId: parent.Id, isCompleted: true, completedAt: Now);
        var second = MemoItem.Create(MemoItemType.Task, "B", Day, parentId: parent.Id);
        var updated = CompletionRules.SetCompleted([parent, first, second], second.Id, completed: true, Now);

        Assert.True(updated.Single(item => item.Id == parent.Id).IsCompleted);
    }

    [Fact]
    public void UncompletingAChildReopensTheParentAndLeavesTheSibling()
    {
        var parent = MemoItem.Create(MemoItemType.Task, "Parent", Day, isCompleted: true, completedAt: Now);
        var first = MemoItem.Create(MemoItemType.Task, "A", Day, parentId: parent.Id, isCompleted: true, completedAt: Now);
        var second = MemoItem.Create(MemoItemType.Task, "B", Day, parentId: parent.Id, isCompleted: true, completedAt: Now);
        var updated = CompletionRules.SetCompleted([parent, first, second], first.Id, completed: false, Now);

        Assert.False(updated.Single(item => item.Id == parent.Id).IsCompleted);
        Assert.False(updated.Single(item => item.Id == first.Id).IsCompleted);
        Assert.True(updated.Single(item => item.Id == second.Id).IsCompleted);
    }

    [Fact]
    public void UncompletingAParentLeavesChildrenCompleted()
    {
        var parent = MemoItem.Create(MemoItemType.Task, "Parent", Day, isCompleted: true, completedAt: Now);
        var child = MemoItem.Create(MemoItemType.Task, "Child", Day, parentId: parent.Id, isCompleted: true, completedAt: Now);
        var updated = CompletionRules.SetCompleted([parent, child], parent.Id, completed: false, Now);

        Assert.False(updated.Single(item => item.Id == parent.Id).IsCompleted);
        Assert.True(updated.Single(item => item.Id == child.Id).IsCompleted);
    }

    [Fact]
    public void NotesDoNotComplete()
    {
        var note = MemoItem.Create(MemoItemType.Note, "Note", Day);
        var updated = CompletionRules.SetCompleted([note], note.Id, completed: true, Now);

        Assert.False(updated[0].IsCompleted);
        Assert.Null(updated[0].CompletedAt);
    }

    [Fact]
    public void SubtasksAreOnlyOneLevelAndNotesCannotHaveThem()
    {
        var task = MemoItem.Create(MemoItemType.Task, "Task", Day);
        var sub = MemoItem.Create(MemoItemType.Task, "Sub", Day, parentId: task.Id);
        var note = MemoItem.Create(MemoItemType.Note, "Note", Day);

        Assert.True(TaskHierarchy.CanAddSubtask(task));
        Assert.False(TaskHierarchy.CanAddSubtask(sub));
        Assert.False(TaskHierarchy.CanAddSubtask(note));
    }
}
