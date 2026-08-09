import SwiftUI

// MARK: - File Browser View

struct FilesView: View {

    let server: ExarotonServer

    @EnvironmentObject var appState: AppState
    @State private var rootInfo: FileInfo?
    @State private var navigationPath: [FileInfo] = []
    @State private var isLoading = false
    @State private var editingFile: FileInfo?
    @State private var fileContent: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var currentDir: FileInfo? { navigationPath.last ?? rootInfo }

    var body: some View {
        VStack(spacing: 0) {

            // Breadcrumb
            if !navigationPath.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        Button("root") { navigationPath = [] }
                            .tint(Color(red: 0.3, green: 0.8, blue: 0.5))
                        ForEach(navigationPath.indices, id: \.self) { i in
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.3))
                            Button(navigationPath[i].name) {
                                navigationPath = Array(navigationPath.prefix(i + 1))
                            }
                            .tint(.white.opacity(0.7))
                        }
                    }
                    .font(.system(size: 12, design: .rounded))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Color.white.opacity(0.03))
            }

            if let err = errorMessage {
                Text(err)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Color(red: 1, green: 0.4, blue: 0.4))
                    .padding()
            }

            if isLoading {
                Spacer()
                ProgressView().tint(Color(red: 0.3, green: 0.9, blue: 0.5))
                Spacer()
            } else {
                List {
                    let children = currentDir?.children ?? []
                    if children.isEmpty {
                        Text("Empty directory")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                            .listRowBackground(Color.white.opacity(0.04))
                    }
                    ForEach(children.sorted { ($0.isDirectory ? 0 : 1) < ($1.isDirectory ? 0 : 1) }) { item in
                        fileRow(item)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .sheet(item: $editingFile) { file in
            FileEditorView(
                file: file,
                content: $fileContent,
                isSaving: $isSaving,
                onSave: { await saveFile(file) }
            )
        }
        .task {
            await loadDirectory(path: "")
        }
    }

    private func fileRow(_ item: FileInfo) -> some View {
        Button {
            if item.isDirectory {
                navigationPath.append(item)
                Task { await loadDirectory(path: item.path) }
            } else if item.isTextFile || item.isConfigFile {
                Task {
                    fileContent = (try? await appState.client.getFileData(serverId: server.id, path: item.path)) ?? ""
                    editingFile = item
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.isDirectory ? "folder.fill" : fileIcon(item))
                    .font(.system(size: 18))
                    .foregroundStyle(item.isDirectory
                        ? Color(red: 0.9, green: 0.7, blue: 0.2)
                        : Color(red: 0.5, green: 0.7, blue: 1.0))
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                    if let size = item.size, !item.isDirectory {
                        Text(formatBytes(size))
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }

                Spacer()

                if item.isDirectory {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.white.opacity(0.04))
    }

    private func fileIcon(_ item: FileInfo) -> String {
        let ext = (item.name as NSString).pathExtension.lowercased()
        switch ext {
        case "txt", "log":  return "doc.text.fill"
        case "json":        return "curlybraces"
        case "yml", "yaml": return "list.bullet.indent"
        case "properties":  return "gearshape.fill"
        case "jar":         return "cube.fill"
        case "zip":         return "archivebox.fill"
        default:            return "doc.fill"
        }
    }

    private func loadDirectory(path: String) async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            let info = try await appState.client.getFileInfo(serverId: server.id, path: path)
            if path.isEmpty {
                rootInfo = info
            } else if let idx = navigationPath.lastIndex(where: { $0.path == path }) {
                navigationPath[idx] = info
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveFile(_ file: FileInfo) async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await appState.client.writeFileData(serverId: server.id, path: file.path, content: fileContent)
            editingFile = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func formatBytes(_ bytes: Int) -> String {
        let kb = Double(bytes) / 1024
        if kb < 1 { return "\(bytes) B" }
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        return String(format: "%.1f MB", kb / 1024)
    }
}

// MARK: - File Editor Sheet

struct FileEditorView: View {
    let file: FileInfo
    @Binding var content: String
    @Binding var isSaving: Bool
    let onSave: () async -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.06, blue: 0.08).ignoresSafeArea()
                TextEditor(text: $content)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(12)
            }
            .navigationTitle(file.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.tint(.white.opacity(0.5))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isSaving {
                        ProgressView().tint(Color(red: 0.3, green: 0.9, blue: 0.5))
                    } else {
                        Button("Save") { Task { await onSave() } }
                            .tint(Color(red: 0.3, green: 0.9, blue: 0.5))
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
