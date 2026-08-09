import SwiftUI

// MARK: - Server Detail View (Tab Container)

struct ServerDetailView: View {

    let server: ExarotonServer

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notifService: NotificationService
    @State private var selectedTab = 0
    @State private var liveServer: ExarotonServer?
    @State private var webSocket: ServerWebSocket?
    @State private var wsURL: URL?

    var currentServer: ExarotonServer { liveServer ?? server }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.07, blue: 0.05), Color(red: 0.04, green: 0.05, blue: 0.09)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {

                // Server Hero Header
                heroHeader

                // Tab Bar
                tabBar

                // Content
                TabView(selection: $selectedTab) {
                    OverviewTab(server: currentServer, webSocket: webSocket)
                        .tag(0)
                    ConsoleView(server: currentServer, webSocket: webSocket)
                        .tag(1)
                    StatsView(webSocket: webSocket)
                        .tag(2)
                    PlayersView(server: currentServer)
                        .tag(3)
                    FilesView(server: currentServer)
                        .tag(4)
                    ServerSettingsView(server: currentServer)
                        .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: selectedTab)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await setupWebSocket()
        }
        .onDisappear {
            webSocket?.disconnect()
        }
    }

    // MARK: Hero Header

    private var heroHeader: some View {
        VStack(spacing: 8) {
            Text(currentServer.name)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                StatusBadge(status: currentServer.status)
                    .statusGlow(currentServer.status)

                Text(currentServer.address)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }

            // Action Buttons
            if !currentServer.status.isTransitioning {
                HStack(spacing: 12) {
                    if currentServer.status.isOnline {
                        ActionButton(label: "Stop", icon: "stop.fill", color: Color(red: 1, green: 0.35, blue: 0.35)) {
                            await performAction { try await appState.client.stopServer(id: server.id) }
                        }
                        ActionButton(label: "Restart", icon: "arrow.clockwise", color: Color(red: 0.8, green: 0.5, blue: 1.0)) {
                            await performAction { try await appState.client.restartServer(id: server.id) }
                        }
                    } else if currentServer.status == .offline {
                        ActionButton(label: "Start", icon: "play.fill", color: Color(red: 0.3, green: 0.9, blue: 0.5)) {
                            await performAction { try await appState.client.startServer(id: server.id) }
                        }
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .animation(.spring(duration: 0.4), value: currentServer.status)
    }

    // MARK: Tab Bar

    private var tabBar: some View {
        let tabs: [(String, String)] = [
            ("Overview", "house.fill"),
            ("Console", "terminal.fill"),
            ("Stats",   "chart.bar.fill"),
            ("Players", "person.2.fill"),
            ("Files",   "folder.fill"),
            ("Settings","gear")
        ]

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(tabs.indices, id: \.self) { i in
                    let (name, icon) = tabs[i]
                    Button {
                        selectedTab = i
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: icon)
                                .font(.system(size: 12, weight: .semibold))
                            Text(name)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .foregroundStyle(selectedTab == i ? .black : .white.opacity(0.5))
                        .background(
                            Capsule()
                                .fill(selectedTab == i
                                    ? LinearGradient(
                                        colors: [Color(red: 0.3, green: 1.0, blue: 0.5), Color(red: 0.1, green: 0.7, blue: 0.9)],
                                        startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [Color.white.opacity(0.07), Color.white.opacity(0.07)],
                                        startPoint: .leading, endPoint: .trailing))
                        )
                        .animation(.spring(duration: 0.3), value: selectedTab)
                    }
                    .buttonStyle(GlassButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.white.opacity(0.03))
    }

    // MARK: WebSocket Setup

    private func setupWebSocket() async {
        guard let url = await appState.client.webSocketURL(serverId: server.id) else { return }
        let ws = ServerWebSocket(serverId: server.id, wsURL: url)
        ws.onStatusChange = { [weak ws] old, new in
            Task { @MainActor in
                notifService.handleStatusChange(serverName: server.name, from: old, to: new)
            }
        }
        ws.connect()
        ws.subscribe(to: .status)
        webSocket = ws
        wsURL = url
    }

    private func performAction(_ action: @escaping () async throws -> Void) async {
        do {
            try await action()
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let label: String
    let icon: String
    let color: Color
    let action: () async -> Void
    @State private var loading = false

    var body: some View {
        Button {
            Task {
                loading = true
                await action()
                loading = false
            }
        } label: {
            HStack(spacing: 6) {
                if loading {
                    ProgressView().scaleEffect(0.7).tint(.white)
                } else {
                    Image(systemName: icon).font(.system(size: 12, weight: .semibold))
                }
                Text(label).font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(color.opacity(0.2))
                    .overlay(Capsule().strokeBorder(color.opacity(0.5), lineWidth: 1))
            )
        }
        .buttonStyle(GlassButtonStyle())
        .disabled(loading)
    }
}

// MARK: - Overview Tab

struct OverviewTab: View {
    let server: ExarotonServer
    let webSocket: ServerWebSocket?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {

                // Info grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    InfoTile(icon: "person.2.fill", label: "Players", value: "\(server.players.count) / \(server.players.max)", color: Color(red: 0.3, green: 0.8, blue: 1.0))
                    InfoTile(icon: "cube.fill", label: "Software", value: server.software.map { "\($0.name) \($0.version)" } ?? "—", color: Color(red: 0.7, green: 0.5, blue: 1.0))
                    InfoTile(icon: "network", label: "Address", value: server.address, color: Color(red: 0.3, green: 1.0, blue: 0.6))
                    InfoTile(icon: "quote.bubble.fill", label: "MOTD", value: server.motd.isEmpty ? "None" : server.motd, color: Color(red: 1.0, green: 0.7, blue: 0.3))
                }
                .padding(.horizontal, 16)

                // Online player list
                if !server.players.list.isEmpty {
                    GlassCard(cornerRadius: 18, padding: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Online Players")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .textCase(.uppercase)
                                .tracking(1)
                                .foregroundStyle(.white.opacity(0.4))
                            ForEach(server.players.list, id: \.self) { name in
                                HStack(spacing: 10) {
                                    AsyncImage(url: URL(string: "https://crafatar.com/avatars/\(name)?size=32&overlay")) { img in
                                        img.resizable().frame(width: 28, height: 28).clipShape(RoundedRectangle(cornerRadius: 6))
                                    } placeholder: {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.white.opacity(0.1))
                                            .frame(width: 28, height: 28)
                                    }
                                    Text(name)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.85))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 16)
                }

                Spacer(minLength: 32)
            }
            .padding(.top, 12)
        }
    }
}

struct InfoTile: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        GlassCard(cornerRadius: 16, padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.4))
                Text(value)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
