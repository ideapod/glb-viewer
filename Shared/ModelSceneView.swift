import SwiftUI
import SceneKit

/// SwiftUI wrapper around SCNView, configured with SceneKit's built-in trackball camera
/// controller (orbit / pan / zoom, driven by mouse and trackpad gestures) framed on whatever
/// scene it's given.
///
/// This view is the one place that owns "what does the viewer widget look like." The app
/// window and the Quick Look preview extension both use it, so interaction behavior stays
/// consistent between the two.
struct ModelSceneView: NSViewRepresentable {
    let scene: SCNScene

    func makeNSView(context: Context) -> SCNView {
        let view = SCNView()
        view.autoenablesDefaultLighting = true
        view.antialiasingMode = .multisampling4X
        view.backgroundColor = .windowBackgroundColor
        apply(scene: scene, to: view)
        return view
    }

    func updateNSView(_ nsView: SCNView, context: Context) {
        guard nsView.scene !== scene else { return }
        apply(scene: scene, to: nsView)
    }

    private func apply(scene: SCNScene, to view: SCNView) {
        view.scene = scene
        CameraFraming.configure(view, for: scene)
    }
}
