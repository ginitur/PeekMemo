using System.Globalization;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Input;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Threading;
using PeekMeow.Core.Daily;
using PeekMeow.Core.Layout;
using PeekMeow.Windows.ViewModels;
using PeekMeow.Windows.Windowing;

namespace PeekMeow.Windows.Views;

public partial class DailyMemoView : UserControl
{
    DailyMemoViewModel? _model;
    CategoryPopupWindow? _categoryWindow;
    bool _categoryHold;
    bool _blurArmed;
    bool _armingDate;
    bool _checkHold;
    bool _dismissQueued;
    bool _atmosphereLight = true;
    Action? _afterCategoryClose;

    public DailyMemoView()
    {
        InitializeComponent();
        QuoteText.Text = BrandQuote.Text;
        SizeChanged += (_, _) =>
        {
            UpdateQuote();
            UpdateAtmosphere();
        };
        DataContextChanged += (_, _) => HookModel();
    }

    public void ApplyTheme(Color ink, Color line, Color popup)
    {
        ReplaceBrush("MemoInk", ink);
        ReplaceBrush("MemoMuted", Color.FromArgb(128, ink.R, ink.G, ink.B));
        ReplaceBrush("MemoLine", line);
        ReplaceBrush("MemoPopup", popup);
    }

    public void SetAtmosphereLight(bool lightBackground)
    {
        _atmosphereLight = lightBackground;
        UpdateAtmosphere();
    }

    public void DismissTransientUi()
    {
        if (_dismissQueued || (!DatePopup.IsOpen && _categoryWindow is null && !HasOpenContextMenu(this)))
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
            _model.PropertyChanged -= OnModelPropertyChanged;
        }

        _model = DataContext as DailyMemoViewModel;
        if (_model is null)
        {
            return;
        }

        _model.EditorFocusRequested += OnEditorFocusRequested;
        _model.BlurSuspended += OnBlurSuspended;
        _model.CloseCategoryMenu += OnCloseCategoryMenu;
        _model.PropertyChanged += OnModelPropertyChanged;
        UpdateQuote();
    }

    void OnModelPropertyChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs args)
    {
        if (args.PropertyName is null or nameof(DailyMemoViewModel.IsAddingRoot) or nameof(DailyMemoViewModel.IsEditingCategory))
        {
            UpdateQuote();
        }
    }

    void OnBlurSuspended() => _blurArmed = false;

    void OnCloseCategoryMenu() => _categoryWindow?.Close();

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
        if (_categoryWindow is not null)
        {
            _categoryWindow.Close();
            return;
        }

        if (_model is null)
        {
            return;
        }

        var window = new CategoryPopupWindow(_model, this);
        _categoryWindow = window;
        _categoryHold = true;
        _model.BeginSurfaceHold();
        window.Closed += (_, _) => OnCategoryWindowClosed();
        window.ShowNear(CategoryButton);
    }

    protected override void OnPreviewMouseDown(MouseButtonEventArgs e)
    {
        base.OnPreviewMouseDown(e);
        if (_categoryWindow is null || e.OriginalSource is not DependencyObject source || IsInside(source, CategoryButton))
        {
            return;
        }

        _categoryWindow.Close();
    }

    public void OnDatePopupOpened(object sender, EventArgs e) => _model?.OpenDatePicker();

    public void OnDatePopupClosed(object sender, EventArgs e) =>
        _model?.NotifyDatePopupClosed(DateTimeOffset.Now);

    void OnCategoryWindowClosed()
    {
        _categoryWindow = null;
        if (_categoryHold)
        {
            _categoryHold = false;
            _model?.EndSurfaceHold(DateTimeOffset.Now);
        }

        var follow = _afterCategoryClose;
        _afterCategoryClose = null;
        follow?.Invoke();
    }

    void UpdateQuote()
    {
        var tall = BrandQuote.IsVisible(ActualHeight);
        var busy = _model is { IsAddingRoot: true } or { IsEditingCategory: true };
        QuoteText.Visibility = tall && !busy ? Visibility.Visible : Visibility.Collapsed;
    }

    void UpdateAtmosphere()
    {
        var layout = AtmosphereMark.Place(ActualWidth, ActualHeight, _atmosphereLight);
        if (layout.Width < 1 || layout.Opacity < 0.01)
        {
            AtmosphereImage.Visibility = Visibility.Collapsed;
            return;
        }

        AtmosphereImage.Visibility = Visibility.Visible;
        AtmosphereImage.Width = layout.Width;
        AtmosphereImage.Opacity = layout.Opacity;
        AtmosphereImage.Margin = new Thickness(0, 0, -layout.Bleed, -layout.Bleed);
    }

    public string DescribeInterface(bool openCategoryMenu)
    {
        if (openCategoryMenu && _categoryWindow is null && _model is not null)
        {
            OnCategoryClick(this, new RoutedEventArgs());
        }

        UpdateLayout();
        UpdateQuote();
        UpdateAtmosphere();
        var tall = BrandQuote.IsVisible(ActualHeight);
        var adding = _model?.IsAddingRoot == true;
        var editingCategory = _model?.IsEditingCategory == true;
        var popupHwnd = _categoryWindow is null ? IntPtr.Zero : new WindowInteropHelper(_categoryWindow).Handle;
        var panel = Window.GetWindow(this);
        var panelHwnd = panel is null ? IntPtr.Zero : new WindowInteropHelper(panel).Handle;
        var ownerHwnd = WindowStyles.OwnerOf(popupHwnd);
        var builder = new StringBuilder();
        builder.AppendLine(string.Create(CultureInfo.InvariantCulture, $"Panel ActualWidth: {ActualWidth:0.##}"));
        builder.AppendLine(string.Create(CultureInfo.InvariantCulture, $"Panel ActualHeight: {ActualHeight:0.##}"));
        builder.AppendLine($"Quote Visibility: {QuoteText.Visibility}");
        builder.AppendLine($"Quote eligibility: {(tall && !adding && !editingCategory ? "yes" : "no")}");
        builder.AppendLine($"Quote tall enough: {(tall ? "yes" : "no")}");
        builder.AppendLine($"IsAddingRoot: {(adding ? "yes" : "no")}");
        builder.AppendLine($"IsEditingCategory: {(editingCategory ? "yes" : "no")}");
        builder.AppendLine($"Atmosphere Visibility: {AtmosphereImage.Visibility}");
        builder.AppendLine(string.Create(CultureInfo.InvariantCulture, $"Atmosphere Width: {AtmosphereImage.Width:0.##}"));
        builder.AppendLine(string.Create(CultureInfo.InvariantCulture, $"Atmosphere ActualWidth: {AtmosphereImage.ActualWidth:0.##}"));
        builder.AppendLine(string.Create(CultureInfo.InvariantCulture, $"Atmosphere ActualHeight: {AtmosphereImage.ActualHeight:0.##}"));
        builder.AppendLine(string.Create(CultureInfo.InvariantCulture, $"Atmosphere Opacity: {AtmosphereImage.Opacity:0.###}"));
        builder.AppendLine($"Atmosphere Source: {AtmosphereImage.Source}");
        builder.AppendLine($"Category popup HWND: {popupHwnd}");
        builder.AppendLine($"Panel HWND: {panelHwnd}");
        builder.AppendLine($"Owner HWND: {ownerHwnd}");
        builder.AppendLine($"Popup topmost: {(WindowStyles.IsTopmost(popupHwnd) ? "yes" : "no")}");
        builder.Append($"Panel topmost: {(WindowStyles.IsTopmost(panelHwnd) ? "yes" : "no")}");
        return builder.ToString();
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
        if (_categoryWindow is null)
        {
            Defer(follow);
            return;
        }

        _afterCategoryClose = () => Defer(follow);
        _categoryWindow.Close();
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
        _categoryWindow?.Close();
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

    static bool IsInside(DependencyObject source, DependencyObject ancestor)
    {
        var current = source;
        while (current is not null)
        {
            if (ReferenceEquals(current, ancestor))
            {
                return true;
            }

            current = VisualTreeHelper.GetParent(current);
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
