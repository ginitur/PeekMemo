import AppKit

@main
enum PeekMemoMain {
    static func main() {
        let arguments = CommandLine.arguments
        if arguments.contains("--version") {
            print(AppIdentity.report)
            exit(0)
        }
        if arguments.contains("--smoke-expanded") {
            let report = MainActor.assumeIsolated { AtmosphereArtwork.smokeReport() }
            print(report)
            exit(0)
        }

        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        MainActor.assumeIsolated {
            app.delegate = AppDelegate.shared
        }
        app.run()
    }
}
