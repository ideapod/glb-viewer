import QuickLookThumbnailing
import SceneKit
import Metal

/// Renders the small icon shown in Finder's icon/gallery views and the Quick Look panel's
/// loading state, by offscreen-rendering one still frame of the scene.
class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(
        for request: QLFileThumbnailRequest,
        _ handler: @escaping (QLThumbnailReply?, Error?) -> Void
    ) {
        do {
            let scene = try GLBLoader.loadScene(from: request.fileURL)

            guard let device = MTLCreateSystemDefaultDevice() else {
                handler(nil, GLBLoadError.emptyScene)
                return
            }
            let renderer = SCNRenderer(device: device, options: nil)
            renderer.scene = scene
            renderer.autoenablesDefaultLighting = true

            if let existingCamera = CameraFraming.existingCameraNode(in: scene) {
                renderer.pointOfView = existingCamera
            } else {
                let camera = CameraFraming.makeFramingCamera(for: scene)
                scene.rootNode.addChildNode(camera)
                renderer.pointOfView = camera
            }

            let size = request.maximumSize
            let reply = QLThumbnailReply(contextSize: size) { context in
                let image = renderer.snapshot(atTime: 0, with: size, antialiasingMode: .multisampling4X)
                guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                    return false
                }
                context.draw(cgImage, in: CGRect(origin: .zero, size: size))
                return true
            }
            handler(reply, nil)
        } catch {
            handler(nil, error)
        }
    }
}
