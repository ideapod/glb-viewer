import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var model: ViewerModel
    @State private var isTargeted = false

    private var glbType: UTType {
        UTType(filenameExtension: "glb") ?? .data
    }

    var body: some View {
        Group {
            if let scene = model.scene {
                ModelSceneView(scene: scene)
            } else {
                dropZone
            }
        }
        .navigationTitle(model.fileName ?? "GLB Viewer")
        .toolbar {
            ToolbarItem {
                Button("Open…", action: openPanel)
            }
        }
        .alert(
            "Couldn't load file",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )
        ) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted, perform: handleDrop)
        .onReceive(NotificationCenter.default.publisher(for: .openFileRequested)) { _ in
            openPanel()
        }
        .frame(minWidth: 480, minHeight: 360)
    }

    private var dropZone: some View {
        VStack(spacing: 12) {
            Image(systemName: "move.3d")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Drop a .glb file here")
                .foregroundStyle(.secondary)
            Button("Open…", action: openPanel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isTargeted ? Color.accentColor.opacity(0.12) : Color.clear)
        .contentShape(Rectangle())
    }

    private func openPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [glbType]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            model.open(url: url)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url else { return }
            DispatchQueue.main.async { model.open(url: url) }
        }
        return true
    }
}
