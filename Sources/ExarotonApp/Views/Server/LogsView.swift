import SwiftUI

// MARK: - Logs View

struct LogsView: View {

    let server: ExarotonServer

    @EnvironmentObject var appState: AppState
    @State private var logContent: String = ""
    @State private var isLoading = false
    @State private var shareURL: String?
    @State private var isSharing = false
    @State private var showShareAlert = false

    var body: some View {
        VStack(spacing: 0) {

            // Toolbar
            HStack {
                Button {
                    Task { await loadLogs() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.3, green: 0.9, blue: 0.5))
                }

                Spacer()

                Button {
                    Task { await shareLogs() }
                } label: {
                    if isSharing {
                        ProgressView().scaleEffect(0.8).tint(.white)
                    } else {
                        Label("Share to mclo.gs", systemImage: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .disabled(isSharing || logContent.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.03))

            if isLoading {
                Spacer()
                ProgressView().tint(Color(red: 0.3, green: 0.9, blue: 0.5))
                Spacer()
            } else if logContent.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundStyle(.white.opacity(0.2))
                    Text("No logs loaded")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                    Button("Load Logs") { Task { await loadLogs() } }
                        .tint(Color(red: 0.3, green: 0.9, blue: 0.5))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    Text(logContent)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color(white: 0.75))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .textSelection(.enabled)
                }
                .background(Color.black.opacity(0.4))
            }
        }
        .alert("Shared to mclo.gs", isPresented: $showShareAlert) {
            Button("Copy Link") {
                UIPasteboard.general.string = shareURL
            }
            Button("Open in Safari") {
                if let url = shareURL.flatMap({ URL(string: $0) }) {
                    UIApplication.shared.open(url)
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(shareURL ?? "")
        }
        .task { await loadLogs() }
    }

    private func loadLogs() async {
        isLoading = true
        defer { isLoading = false }
        do {
            logContent = try await appState.client.getLogs(serverId: server.id)
        } catch {
            logContent = "Error: \(error.localizedDescription)"
        }
    }

    private func shareLogs() async {
        isSharing = true
        defer { isSharing = false }
        do {
            let result = try await appState.client.shareLogs(serverId: server.id)
            shareURL = result.url
            showShareAlert = true
        } catch {
            // Handle error silently or show toast
        }
    }
}
