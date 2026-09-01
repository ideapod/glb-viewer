import Cocoa
import Quartz
import SceneKit

/// Powers the spacebar / full Quick Look preview panel in Finder: an interactive SCNView with
/// the same orbit/pan/zoom controls as the main app window.
class PreviewViewController: NSViewController, QLPreviewingController {
    override var nibName: NSNib.Name? { nil }

    override func loadView() {
        view = NSView()
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        do {
            let scene = try GLBLoader.loadScene(from: url)

            let sceneView = SCNView(frame: view.bounds)
            sceneView.autoresizingMask = [.width, .height]
            sceneView.autoenablesDefaultLighting = true
            sceneView.antialiasingMode = .multisampling4X
            sceneView.backgroundColor = .windowBackgroundColor
            sceneView.scene = scene
            CameraFraming.configure(sceneView, for: scene)

            view.subviews.forEach { $0.removeFromSuperview() }
            view.addSubview(sceneView)

            handler(nil)
        } catch {
            handler(error)
        }
    }
}
