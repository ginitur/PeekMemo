using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Threading;
using PeekMemo.Windows.ViewModels;

namespace PeekMemo.Windows.Views;

public partial class DailyMemoView : UserControl
{
    DailyMemoViewModel? _model;
    bool _blurArmed;
    bool _armingDate;
    bool _checkHold;
    bool _dismissQueued;
    Action? _afterCategoryClose;

    public DailyMemoView()
    {
        InitializeComponent();
        DataContextChanged += (_, _) => HookModel();
    }

    public void ApplyTheme(Color ink, Color line, Color popup)
    {
        ReplaceBrush("MemoInk", ink);
        ReplaceBrush("MemoMuted", Color.FromArgb(128, ink.R, ink.G, ink.B));
        ReplaceBrush("MemoLine", line);
        ReplaceBrush("MemoPopup", popup);
    }

    public void DismissTransientUi()
    {
        if (_dismissQueued || (!DatePopup.IsOpen && !CategoryPopup.IsOpen && !HasOpenContextMenu(this)))
        {
            return;
        }

        _dismissQueued = true;
        Dispatcher.BeginInvoke(new Action(CloseTransientUi));
    }

    void HookModel()
    {
        if (_model is not null)
        {
            _model.EditorFocusRequested -= OnEditorFocusRequested;
            _model.BlurSuspended -= OnBlurSuspended;
            _model.CloseCategoryMenu -= OnCloseCategoryMenu;
        }

        _model = DataContext as DailyMemoViewModel;
        if (_model is null)
        {
            return;
        }

        _model.EditorFocusRequested += OnEditorFocusRequested;
        _model.BlurSuspended += OnBlurSuspended;
        _model.CloseCategoryMenu += OnCloseCategoryMenu;
    }

    void OnBlurSuspended() => _blurArmed = false;

    void OnCloseCategoryMenu()
    {
        if (CategoryPopup.IsOpen)
        {
            CategoryPopup.IsOpen = false;
        }
    }

    void OnEditorFocusRequested() =>
        Dispatcher.BeginInvoke(new Action(FocusEditor), DispatcherPriority.Input);

    void FocusEditor()
    {
        if (_model is null || !_model.Session.Editing.IsOpen)
        {
            return;
        }

        var box = FindEditor(this);
        if (box is null)
        {
            return;
        }

        _blurArmed = false;
        box.Focus();
        box.CaretIndex = box.Text.Length;
        if (box.Text.Length > 0)
        {
            box.SelectAll();
        }

        Dispatcher.BeginInvoke(new Action(() =>
        {
            if (_model is not null && _model.Session.Editing.IsOpen)
            {
                _blurArmed = true;
            }
        }), DispatcherPriority.ContextIdle);
    }

    public void OnEditorPreviewKeyDown(object sender, KeyEventArgs e)
    {
        if (_model is null)
        {
            return;
        }

        if (e.Key == Key.Escape)
        {
            _model.SubmitKey(enter: false, control: false, escape: true);
            e.Handled = true;
            return;
        }

        if (e.Key is Key.Enter or Key.Return)
        {
            var control = (Keyboard.Modifiers & ModifierKeys.Control) == ModifierKeys.Control;
            _model.SubmitKey(enter: true, control: control, escape: false);
            e.Handled = true;
        }
    }

    public void OnEditorLostKeyboardFocus(object sender, KeyboardFocusChangedEventArgs e)
    {
        if (!_blurArmed || _model is null)
        {
            return;
        }

        _blurArmed = false;
        _model.CommitBlur(DateTimeOffset.Now);
    }

    public void OnHeaderSizeChanged(object sender, SizeChangedEventArgs e)
    {
        var available = HeaderHost.ActualWidth - CategoryButton.ActualWidth - 72;
        DateText.MaxWidth = Math.Max(36, available);
    }

    public void OnDateClick(object sender, RoutedEventArgs e)
    {
        if (DatePopup.IsOpen)
        {
            DatePopup.IsOpen = false;
            return;
        }

        ArmCalendar();
        OpenPopup(DatePopup);
    }

    public void OnCategoryClick(object sender, RoutedEventArgs e)
    {
        if (CategoryPopup.IsOpen)
        {
            CategoryPopup.IsOpen = false;
            return;
        }

        OpenPopup(CategoryPopup);
    }

    public void OnDatePopupOpened(object sender, EventArgs e) => _model?.OpenDatePicker();

    public void OnDatePopupClosed(object sender, EventArgs e) =>
        _model?.NotifyDatePopupClosed(DateTimeOffset.Now);

    public void OnCategoryPopupOpened(object sender, EventArgs e) => _model?.BeginSurfaceHold();

    public void OnCategoryPopupClosed(object sender, EventArgs e)
    {
        _model?.EndSurfaceHold(DateTimeOffset.Now);
        var follow = _afterCategoryClose;
        _afterCategoryClose = null;
        follow?.Invoke();
    }

    public void OnCalendarSelected(object sender, SelectionChangedEventArgs e)
    {
        if (_armingDate || _model is null || MemoCalendar.SelectedDate is not DateTime chosen)
        {
            return;
        }

        _model.SelectDate(DateOnly.FromDateTime(chosen));
        DatePopup.IsOpen = false;
    }

    public void OnNewCategoryClick(object sender, RoutedEventArgs e) =>
        CloseCategoryThen(() => _model?.StartNewCategory());

    public void OnRenameCategory(object sender, RoutedEventArgs e)
    {
        if ((sender as FrameworkElement)?.DataContext is not CategoryChoice choice)
        {
            return;
        }

        var id = choice.Id;
        CloseCategoryThen(() => _model?.StartRenameCategory(id));
    }

    public void OnOpenAddMenu(object sender, RoutedEventArgs e)
    {
        if (sender is not DependencyObject source)
        {
            return;
        }

        var current = source;
        while (current is not null)
        {
            if (current is FrameworkElement element && element.ContextMenu is ContextMenu menu)
            {
                menu.PlacementTarget = element;
                menu.IsOpen = true;
                return;
            }

            current = VisualTreeHelper.GetParent(current);
        }
    }

    public void OnAddTaskMenu(object sender, RoutedEventArgs e) =>
        Defer(() => _model?.StartAddTask());

    public void OnAddNoteMenu(object sender, RoutedEventArgs e) =>
        Defer(() => _model?.StartAddNote());

    public void OnMenuOpened(object sender, RoutedEventArgs e) => _model?.BeginSurfaceHold();

    public void OnMenuClosed(object sender, RoutedEventArgs e) =>
        _model?.EndSurfaceHold(DateTimeOffset.Now);

    public void OnCheckClick(object sender, RoutedEventArgs e)
    {
        if ((sender as FrameworkElement)?.DataContext is MemoRowViewModel row)
        {
            _model?.Toggle(row.Id);
        }
    }

    public void OnCheckDown(object sender, MouseButtonEventArgs e)
    {
        if (_checkHold || _model is null)
        {
            return;
        }

        _checkHold = true;
        _model.BeginSurfaceHold();
    }

    public void OnCheckUp(object sender, MouseButtonEventArgs e) => ReleaseCheckHold();

    public void OnCheckLostCapture(object sender, MouseEventArgs e) => ReleaseCheckHold();

    void ReleaseCheckHold()
    {
        if (!_checkHold || _model is null)
        {
            return;
        }

        _checkHold = false;
        _model.EndSurfaceHold(DateTimeOffset.Now);
    }

    void CloseCategoryThen(Action follow)
    {
        if (!CategoryPopup.IsOpen)
        {
            Defer(follow);
            return;
        }

        _afterCategoryClose = () => Defer(follow);
        CategoryPopup.IsOpen = false;
    }

    void Defer(Action action) =>
        Dispatcher.BeginInvoke(action, DispatcherPriority.Background);

    void ArmCalendar()
    {
        if (_model is null)
        {
            return;
        }

        _armingDate = true;
        var day = _model.Session.Board.SelectedDate.ToDateTime(TimeOnly.MinValue);
        MemoCalendar.SelectedDate = day;
        MemoCalendar.DisplayDate = day;
        _armingDate = false;
    }

    void OpenPopup(Popup popup)
    {
        popup.StaysOpen = true;
        popup.IsOpen = true;
        Dispatcher.BeginInvoke(new Action(() =>
        {
            if (popup.IsOpen)
            {
                popup.StaysOpen = false;
            }
        }), DispatcherPriority.Input);
    }

    void CloseTransientUi()
    {
        _dismissQueued = false;
        DatePopup.IsOpen = false;
        CategoryPopup.IsOpen = false;
        CloseContextMenus(this);
    }

    void ReplaceBrush(string key, Color color)
    {
        var brush = new SolidColorBrush(color);
        brush.Freeze();
        Resources.Remove(key);
        Resources.Add(key, brush);
    }

    static TextBox? FindEditor(DependencyObject root)
    {
        var count = VisualTreeHelper.GetChildrenCount(root);
        for (var index = 0; index < count; index++)
        {
            var child = VisualTreeHelper.GetChild(root, index);
            if (child is TextBox box && Equals(box.Tag, "editor"))
            {
                return box;
            }

            var nested = FindEditor(child);
            if (nested is not null)
            {
                return nested;
            }
        }

        return null;
    }

    static bool HasOpenContextMenu(DependencyObject root)
    {
        if (root is FrameworkElement element && element.ContextMenu is { IsOpen: true })
        {
            return true;
        }

        var count = VisualTreeHelper.GetChildrenCount(root);
        for (var index = 0; index < count; index++)
        {
            if (HasOpenContextMenu(VisualTreeHelper.GetChild(root, index)))
            {
                return true;
            }
        }

        return false;
    }

    static void CloseContextMenus(DependencyObject root)
    {
        if (root is FrameworkElement element && element.ContextMenu is { IsOpen: true } menu)
        {
            menu.IsOpen = false;
        }

        var count = VisualTreeHelper.GetChildrenCount(root);
        for (var index = 0; index < count; index++)
        {
            CloseContextMenus(VisualTreeHelper.GetChild(root, index));
        }
    }
}
