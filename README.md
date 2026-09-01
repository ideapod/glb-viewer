# GLB Viewer

A small macOS app for opening `.glb` (binary glTF) files with the normal 3D navigation
controls (orbit, pan, zoom), plus Finder integration: a spacebar Quick Look preview and
Finder icon/gallery thumbnails.

## How it's built

- **UI**: SwiftUI, wrapping an `SCNView` (SceneKit) via `NSViewRepresentable`. SceneKit's
  built-in trackball camera controller (`allowsCameraControl`) provides orbit/pan/zoom for
  free — see [`Shared/ModelSceneView.swift`](Shared/ModelSceneView.swift).
- **glTF loading**: [GLTFSceneKit](https://github.com/magicien/GLTFSceneKit) parses `.glb`
  and converts it into a standard `SCNScene`. This is the only place that library is
  imported — see [`Shared/GLBLoader.swift`](Shared/GLBLoader.swift) — so if the rendering
  stack ever needs to move (e.g. to RealityKit), that's the one seam that changes.
- **Camera framing**: since many glTF files don't define their own camera, or aren't
  centered at the origin, [`Shared/CameraFraming.swift`](Shared/CameraFraming.swift)
  computes a bounding-box-based camera and orbit target so the model is actually in frame
  and rotates around itself, not empty space.
- **Three targets**, sharing all of the above via the `Shared/` source folder:
  - `GLBViewer` — the host app (drag-and-drop, File > Open, double-click from Finder).
  - `PreviewExtension` — `QLPreviewingController`, powers the spacebar preview panel.
  - `ThumbnailExtension` — `QLThumbnailProvider`, powers Finder icon/gallery thumbnails.

The project is defined declaratively in [`project.yml`](project.yml) via
[XcodeGen](https://github.com/yonaskolb/XcodeGen) rather than a hand-maintained
`.xcodeproj` — that file is generated and gitignored.

## One-time setup

```bash
brew install xcodegen   # already done if you're reading this after the initial setup
xcodegen generate
open GLBViewer.xcodeproj
```

## In Xcode (required before the first Run)

Quick Look extensions must be signed with the same team as their host app, and none of
that is set in `project.yml` since it's tied to your personal Apple ID. For **each** of the
three targets (`GLBViewer`, `PreviewExtension`, `ThumbnailExtension`):

1. Select the target in the project navigator's target list.
2. Go to **Signing & Capabilities**.
3. Under **Team**, pick your Apple ID (add one first via Xcode → Settings → Accounts if
   you don't have one there — a free personal team is fine for local use).

Then select the `GLBViewer` scheme and hit **Run** (⌘R).

## Getting the Finder integration to show up

Quick Look extensions are only discovered once the host app has actually been *installed*
somewhere Launch Services indexes — running once from Xcode is normally enough, but if
spacebar preview or thumbnails don't appear:

1. Quit the app if it's running.
2. In Xcode: **Product → Show Build Folder in Finder**, find `GLBViewer.app`, and drag it
   into `/Applications`.
3. Launch it once from `/Applications`, then quit it again.
4. Open **System Settings → General → Login Items & Extensions**, find GLB Viewer, and
   make sure both the preview and thumbnail extensions are toggled on.
5. If it still doesn't show up, reset Quick Look's cache/daemon from Terminal:
   ```bash
   qlmanage -r
   qlmanage -r cache
   ```
6. Select a `.glb` file in Finder and press Space.

## Known scope / not done yet

- No custom app icon (uses the default Xcode placeholder).
- Only `.glb` is registered as a document type today (not plain-text `.gltf` + side
  buffers), since that's what the Finder-preview use case needs. Easy to extend in
  `project.yml`'s `UTExportedTypeDeclarations` if needed later.
