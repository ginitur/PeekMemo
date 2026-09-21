import AppKit

@main
enum PeekMemoMain {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        MainActor.assumeIsolated {
            app.delegate = AppDelegate.shared
        }
        app.run()
    }
}
