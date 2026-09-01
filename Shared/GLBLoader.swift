import Foundation
import SceneKit
import GLTFSceneKit

/// Errors surfaced to the UI (main app window and Quick Look extensions) when a .glb/.gltf
/// file can't be turned into a scene.
enum GLBLoadError: Error, LocalizedError {
    case failedToLoad(underlying: Error)
    case emptyScene

    var errorDescription: String? {
        switch self {
        case .failedToLoad(let underlying):
            return "Couldn't load this file: \(underlying.localizedDescription)"
        case .emptyScene:
            return "The file loaded but contained no visible content."
        }
    }
}

/// Single entry point every target (app, preview extension, thumbnail extension) uses to turn
/// a .glb file on disk into an SCNScene.
///
/// This is intentionally the *only* place that imports GLTFSceneKit. If the rendering stack
/// ever needs to move off SceneKit, this is the one file whose contract (`loadScene(from:) throws
/// -> SCNScene`) needs to change â€” everything downstream just consumes an SCNScene.
enum GLBLoader {
    static func loadScene(from url: URL) throws -> SCNScene {
        let scene: SCNScene
        do {
            let source = GLTFSceneSource(url: url, options: nil)
            scene = try source.scene()
        } catch {
            throw GLBLoadError.failedToLoad(underlying: error)
        }

        guard !scene.rootNode.childNodes.isEmpty else {
            throw GLBLoadError.emptyScene
        }
        return scene
    }
}
