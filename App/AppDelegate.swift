import AppKit

/// Catches "Open With GLB Viewer" / double-click launches from Finder, which arrive as an
/// `application(_:open:)` call rather than through SwiftUI's `.onOpenURL` (that's for URL
/// schemes, not document files).
final class AppDelegate: NSObject, NSApplicationDelegate {
    var onOpen: ((URL) -> Void)?
    private var pendingURL: URL?

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        if let onOpen {
            onOpen(url)
        } else {
            // App launched via double-click before SwiftUI's view hierarchy attached the
            // callback yet; stash it and deliver once it does.
            pendingURL = url
        }
    }

    func deliverPendingURLIfNeeded() {
        guard let pendingURL else { return }
        self.pendingURL = nil
        onOpen?(pendingURL)
    }
}
