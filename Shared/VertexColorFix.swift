import SceneKit

/// Works around a real GLTFSceneKit/Metal incompatibility: for glTF files that carry a
/// `COLOR_0` vertex attribute stored as normalized unsigned bytes (very common for
/// reconstruction/point-cloud-derived meshes with no material and no textures — e.g.
/// sam3d-api output), GLTFSceneKit builds the color `SCNGeometrySource` with
/// `usesFloatComponents: false`. That puts a raw `uchar4` vertex buffer straight into its
/// PBR shader modifier, which current Metal refuses to implicitly convert to `float4`,
/// logging repeated "Error: unsupported conversion uchar4 -> float4" and failing to shade
/// the model.
///
/// This walks the loaded scene and re-encodes any byte-backed `.color` source as a
/// normalized `Float32` source instead, which SceneKit's shader modifiers handle natively.
/// Everything else about the geometry (positions, normals, indices, materials) is left
/// untouched.
enum VertexColorFix {
    static func apply(to scene: SCNScene) {
        scene.rootNode.enumerateHierarchy { node, _ in
            guard let geometry = node.geometry,
                  let patched = patchedGeometry(geometry) else { return }
            node.geometry = patched
        }
    }

    private static func patchedGeometry(_ geometry: SCNGeometry) -> SCNGeometry? {
        let colorSources = geometry.sources(for: .color)
        guard let byteColor = colorSources.first(where: { !$0.usesFloatComponents && $0.bytesPerComponent == 1 }) else {
            return nil
        }
        guard let floatColor = floatColorSource(from: byteColor) else { return nil }

        let otherSources = geometry.sources.filter { $0.semantic != .color }
        let newGeometry = SCNGeometry(sources: otherSources + [floatColor], elements: geometry.elements)
        newGeometry.materials = geometry.materials
        return newGeometry
    }

    private static func floatColorSource(from source: SCNGeometrySource) -> SCNGeometrySource? {
        let componentsPerVector = source.componentsPerVector
        let vectorCount = source.vectorCount
        let stride = source.dataStride
        let offset = source.dataOffset

        var floats = [Float](repeating: 0, count: vectorCount * componentsPerVector)
        source.data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            for vector in 0..<vectorCount {
                let base = offset + vector * stride
                for component in 0..<componentsPerVector {
                    let byte = raw.load(fromByteOffset: base + component, as: UInt8.self)
                    floats[vector * componentsPerVector + component] = Float(byte) / 255.0
                }
            }
        }

        let data = floats.withUnsafeBufferPointer { Data(buffer: $0) }
        return SCNGeometrySource(
            data: data,
            semantic: .color,
            vectorCount: vectorCount,
            usesFloatComponents: true,
            componentsPerVector: componentsPerVector,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: componentsPerVector * MemoryLayout<Float>.size
        )
    }
}
