import SceneKit

/// Helpers for pointing a camera at whatever a loaded glTF scene contains, and for orbiting
/// around its center rather than the world origin. glTF files frequently ship with no camera
/// at all (viewers are expected to supply one), and even when they do, the asset isn't always
/// centered at (0,0,0).
enum CameraFraming {
    /// True if `scene` already defines at least one camera.
    static func existingCameraNode(in scene: SCNScene) -> SCNNode? {
        scene.rootNode.childNodes(passingTest: { node, _ in node.camera != nil }).first
    }

    /// The center of the scene's bounding box, in the root node's coordinate space.
    static func boundingCenter(of scene: SCNScene) -> SCNVector3 {
        let (minBox, maxBox) = scene.rootNode.boundingBox
        return SCNVector3(
            (minBox.x + maxBox.x) / 2,
            (minBox.y + maxBox.y) / 2,
            (minBox.z + maxBox.z) / 2
        )
    }

    /// Builds a camera node positioned to frame the entire scene, for use when the file itself
    /// didn't define one.
    static func makeFramingCamera(for scene: SCNScene) -> SCNNode {
        let (minBox, maxBox) = scene.rootNode.boundingBox
        let center = boundingCenter(of: scene)
        let size = SCNVector3(
            maxBox.x - minBox.x,
            maxBox.y - minBox.y,
            maxBox.z - minBox.z
        )
        let radius = max(max(size.x, size.y), max(size.z, 0.01)) / 2

        let camera = SCNCamera()
        camera.zNear = 0.001
        camera.zFar = Double(radius) * 20 + 1000

        let node = SCNNode()
        node.camera = camera

        let fovRadians = Float(camera.fieldOfView) * .pi / 180
        let distance = radius / CGFloat(tan(fovRadians / 2)) * 1.4
        node.position = SCNVector3(center.x, center.y, center.z + max(distance, 0.05))
        node.look(at: center)
        return node
    }

    /// Ensures `view` has a camera that frames `scene`, adding one if the file didn't supply
    /// its own, and configures the interactive orbit controller to rotate around the model
    /// instead of the world origin.
    static func configure(_ view: SCNView, for scene: SCNScene) {
        let center = boundingCenter(of: scene)

        if let camera = existingCameraNode(in: scene) {
            view.pointOfView = camera
        } else {
            let camera = makeFramingCamera(for: scene)
            scene.rootNode.addChildNode(camera)
            view.pointOfView = camera
        }

        view.allowsCameraControl = true
        view.defaultCameraController.interactionMode = .orbitTurntable
        view.defaultCameraController.target = center
        view.defaultCameraController.inertiaEnabled = true
    }
}
