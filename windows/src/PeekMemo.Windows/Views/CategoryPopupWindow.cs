using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Interop;
using System.Windows.Media;
using PeekMemo.Windows.ViewModels;
using PeekMemo.Windows.Windowing;
using FormsScreen = System.Windows.Forms.Screen;

namespace PeekMemo.Windows.Views;

/// Owned category menu. A WPF Popup HWND falls behind the topmost no-activate panel.
sealed class CategoryPopupWindow : Window
{
    bool _acceptDismiss;

    public CategoryPopupWindow(DailyMemoViewModel model, DailyMemoView ownerView)
    {
        WindowStyle = WindowStyle.None;
        ResizeMode = ResizeMode.NoResize;
        ShowInTaskbar = false;
        ShowActivated = true;
        SizeToContent = SizeToContent.WidthAndHeight;
        WindowStartupLocation = WindowStartupLocation.Manual;
        Background = Brushes.Transparent;
        Topmost = true;
        Focusable = true;
        Title = "PeekMemo";

        var ink = FindBrush(ownerView, "MemoInk", Color.FromRgb(28, 28, 30));
        var line = FindBrush(ownerView, "MemoLine", Color.FromArgb(48, 0, 0, 0));
        var popup = FindBrush(ownerView, "MemoPopup", Color.FromRgb(247, 247, 248));
        var stack = new StackPanel { MinWidth = 180 };
        stack.Children.Add(Item("All Tasks", ink, () => model.ChooseCategory(null)));
        stack.Children.Add(Rule(line));
        foreach (var choice in model.Categories)
        {
            var id = choice.Id;
            var button = Item(choice.Name, ink, () => model.ChooseCategory(id));
            button.MouseRightButtonUp += (_, args) =>
            {
                args.Handled = true;
                model.StartRenameCategory(id);
                Close();
            };
            stack.Children.Add(button);
        }

        stack.Children.Add(Rule(line));
        stack.Children.Add(Item("+ New Category", ink, () =>
        {
            model.StartNewCategory();
            Close();
        }));

        Content = new Border
        {
            Background = popup,
            BorderBrush = line,
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(4),
            Child = stack
        };

        SourceInitialized += (_, _) =>
        {
            var hwnd = new WindowInteropHelper(this).Handle;
            WindowStyles.TrackOverlay(hwnd);
            WindowStyles.KeepTopmostWithoutActivating(hwnd);
        };
        Closed += (_, _) => WindowStyles.ReleaseOverlay(new WindowInteropHelper(this).Handle);
    }

    public void ShowNear(FrameworkElement anchor)
    {
        var owner = Window.GetWindow(anchor);
        if (owner is not null)
        {
            Owner = owner;
            if (owner.Icon is not null)
            {
                Icon = owner.Icon;
            }
        }

        Show();
        UpdateLayout();
        Place(anchor);
        var hwnd = new WindowInteropHelper(this).Handle;
        WindowStyles.TrackOverlay(hwnd);
        WindowStyles.KeepTopmostWithoutActivating(hwnd);
        Activate();
        _acceptDismiss = true;
    }

    protected override void OnDeactivated(EventArgs e)
    {
        base.OnDeactivated(e);
        if (_acceptDismiss)
        {
            Close();
        }
    }

    void Place(FrameworkElement anchor)
    {
        var device = anchor.PointToScreen(new Point(0, anchor.ActualHeight));
        var above = anchor.PointToScreen(new Point(0, 0));
        var source = PresentationSource.FromVisual(anchor);
        var toDip = source?.CompositionTarget?.TransformFromDevice ?? Matrix.Identity;
        var origin = toDip.Transform(device);
        var topOfButton = toDip.Transform(above);
        var width = Math.Max(ActualWidth, 180);
        var height = ActualHeight;
        var screen = FormsScreen.FromPoint(new System.Drawing.Point((int)Math.Round(device.X), (int)Math.Round(device.Y)));
        var area = screen.WorkingArea;
        var topLeft = toDip.Transform(new Point(area.Left, area.Top));
        var bottomRight = toDip.Transform(new Point(area.Right, area.Bottom));
        var left = origin.X;
        var top = origin.Y;
        if (top + height > bottomRight.Y)
        {
            top = topOfButton.Y - height;
        }

        if (left + width > bottomRight.X)
        {
            left = bottomRight.X - width;
        }

        Left = Math.Max(topLeft.X, left);
        Top = Math.Max(topLeft.Y, top);
    }

    static Button Item(string title, Brush ink, Action activate)
    {
        var button = new Button
        {
            Content = title,
            Background = Brushes.Transparent,
            BorderThickness = new Thickness(0),
            Foreground = ink,
            HorizontalContentAlignment = HorizontalAlignment.Left,
            Padding = new Thickness(8, 6, 8, 6),
            Focusable = true,
            Cursor = Cursors.Hand
        };
        button.Click += (_, _) => activate();
        return button;
    }

    static Border Rule(Brush line) => new()
    {
        Height = 1,
        Margin = new Thickness(4, 4, 4, 4),
        Background = line
    };

    static Brush FindBrush(FrameworkElement owner, string key, Color fallback)
    {
        if (owner.TryFindResource(key) is Brush brush)
        {
            return brush;
        }

        var solid = new SolidColorBrush(fallback);
        solid.Freeze();
        return solid;
    }
}
