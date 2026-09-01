import Foundation
import SceneKit

@MainActor
final class ViewerModel: ObservableObject {
    @Published private(set) var scene: SCNScene?
    @Published private(set) var fileName: String?
    @Published var errorMessage: String?

    func open(url: URL) {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            scene = try GLBLoader.loadScene(from: url)
            fileName = url.lastPathComponent
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
