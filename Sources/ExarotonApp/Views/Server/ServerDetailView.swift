import SwiftUI

// MARK: - Server Detail View (Dashboard → NavigationLink pages)

struct ServerDetailView: View {

    let server: ExarotonServer

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notifService: NotificationService
    @State private var liveServer: ExarotonServer?
    @State private var webSocket: ServerWebSocket?
    @State private var copiedAddress = false

    var currentServer: ExarotonServer { liveServer ?? server }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.07, blue: 0.05),
                    Color(red: 0.04, green: 0.05, blue: 0.09)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle glow blob behind the status ring
            Circle()
                .fill(statusColor.opacity(0.06))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(y: -180)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // ── Hero ──
                    heroSection

                    // ── Action Buttons ──
                    actionButtons

                    // ── Quick Stats Row ──
                    quickStatsRow

                    // ── Management Menu ──
                    sectionHeader("Server Management")
                    managementGrid

                    Spacer(minLength: 40)
                }
                .padding(.top, 4)
            }
        }
        .navigationTitle(currentServer.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await setupWebSocket()
            // Keep the task alive to maintain the connection
            try? await Task.sleep(nanoseconds: UInt64.max)
            webSocket?.disconnect()
        }
    }

    // MARK: - Status Color

    private var statusColor: Color {
        switch currentServer.status {
        case .online:                      return Color(red: 0.2, green: 0.9, blue: 0.45)
        case .offline:                     return Color(white: 0.45)
        case .crashed:                     return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .starting, .loading, .pending, .preparing:
            return Color(red: 0.3, green: 0.7, blue: 1.0)
        case .stopping, .saving:           return Color(red: 1.0, green: 0.7, blue: 0.2)
        case .restarting:                  return Color(red: 0.8, green: 0.4, blue: 1.0)
        case .transferring:                return Color(red: 0.3, green: 0.8, blue: 0.9)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 12) {

            // Animated status ring
            ZStack {
                // Outer glow ring
                Circle()
                    .strokeBorder(statusColor.opacity(0.15), lineWidth: 3)
                    .frame(width: 88, height: 88)

                Circle()
                    .strokeBorder(statusColor.opacity(0.5), lineWidth: 2.5)
                    .frame(width: 78, height: 78)

                Image(systemName: statusIcon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(statusColor)
                    .symbolEffect(.pulse, isActive: currentServer.status.isTransitioning)
            }
            .shadow(color: statusColor.opacity(0.35), radius: 16, x: 0, y: 4)
            .padding(.top, 8)

            // Status badge
            StatusBadge(status: currentServer.status)
                .statusGlow(currentServer.status)

            // Address + copy
            Button {
                UIPasteboard.general.string = currentServer.address
                withAnimation(.spring(duration: 0.3)) { copiedAddress = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { copiedAddress = false }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: copiedAddress ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11, weight: .semibold))
                    Text(currentServer.address)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(copiedAddress ? statusColor : .white.opacity(0.45))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
                )
            }
            .buttonStyle(GlassButtonStyle())

            // MOTD
            if !currentServer.motd.isEmpty {
                Text(currentServer.motd)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 40)
            }
        }
        .padding(.vertical, 8)
        .animation(.spring(duration: 0.4), value: currentServer.status)
    }

    private var statusIcon: String {
        switch currentServer.status {
        case .online:       return "power"
        case .offline:      return "moon.fill"
        case .crashed:      return "exclamationmark.triangle.fill"
        case .starting, .loading, .pending, .preparing: return "arrow.up.circle"
        case .stopping, .saving:    return "arrow.down.circle"
        case .restarting:           return "arrow.clockwise"
        case .transferring:         return "arrow.left.arrow.right"
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        Group {
            if !currentServer.status.isTransitioning {
                HStack(spacing: 12) {
                    if currentServer.status.isOnline {
                        ActionButton(label: "Stop", icon: "stop.fill", color: Color(red: 1, green: 0.35, blue: 0.35)) {
                            await performAction { try await appState.client.stopServer(id: server.id) }
                        }
                        ActionButton(label: "Restart", icon: "arrow.clockwise", color: Color(red: 0.8, green: 0.5, blue: 1.0)) {
                            await performAction { try await appState.client.restartServer(id: server.id) }
                        }
                    } else if currentServer.status == .offline || currentServer.status == .crashed {
                        ActionButton(label: "Start Server", icon: "play.fill", color: Color(red: 0.3, green: 0.9, blue: 0.5)) {
                            await performAction { try await appState.client.startServer(id: server.id) }
                        }
                    }
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                // Transitioning indicator
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(statusColor)
                        .scaleEffect(0.8)
                    Text(currentServer.status.description + "…")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(statusColor)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(statusColor.opacity(0.1))
                        .overlay(Capsule().strokeBorder(statusColor.opacity(0.2), lineWidth: 1))
                )
                .transition(.opacity)
            }
        }
        .animation(.spring(duration: 0.4), value: currentServer.status)
    }

    // MARK: - Quick Stats Row

    private var quickStatsRow: some View {
        HStack(spacing: 10) {
            QuickStatPill(
                icon: "person.2.fill",
                value: "\(currentServer.players.count)/\(currentServer.players.max)",
                color: Color(red: 0.3, green: 0.8, blue: 1.0)
            )

            if let sw = currentServer.software {
                QuickStatPill(
                    icon: "cube.fill",
                    value: "\(sw.name) \(sw.version)",
                    color: Color(red: 0.7, green: 0.5, blue: 1.0)
                )
            }

            if currentServer.shared {
                QuickStatPill(
                    icon: "person.2.circle",
                    value: "Shared",
                    color: Color(red: 1.0, green: 0.7, blue: 0.3)
                )
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.35))
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    // MARK: - Management Grid

    private var managementGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {

            NavigationLink {
                if let ws = webSocket {
                    ConsoleView(server: currentServer, webSocket: ws)
                        .navigationTitle("Console")
                        .navigationBarTitleDisplayMode(.inline)
                } else {
                    Text("Connecting...")
                }
            } label: {
                MenuTile(icon: "terminal.fill", title: "Console", subtitle: "Live server output", color: Color(red: 0.3, green: 0.9, blue: 0.5))
            }

            NavigationLink {
                if let ws = webSocket {
                    StatsView(webSocket: ws)
                        .navigationTitle("Stats")
                        .navigationBarTitleDisplayMode(.inline)
                } else {
                    Text("Connecting...")
                }
            } label: {
                MenuTile(icon: "chart.xyaxis.line", title: "Stats", subtitle: "RAM & TPS graphs", color: Color(red: 0.3, green: 0.7, blue: 1.0))
            }

            NavigationLink {
                PlayersView(server: currentServer)
                    .navigationTitle("Players")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                MenuTile(icon: "person.2.fill", title: "Players", subtitle: "Whitelist, ops & bans", color: Color(red: 0.8, green: 0.5, blue: 1.0))
            }

            NavigationLink {
                FilesView(server: currentServer)
                    .navigationTitle("Files")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                MenuTile(icon: "folder.fill", title: "Files", subtitle: "Browse & edit files", color: Color(red: 1.0, green: 0.7, blue: 0.3))
            }

            NavigationLink {
                LogsView(server: currentServer)
                    .navigationTitle("Logs")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                MenuTile(icon: "doc.text.fill", title: "Logs", subtitle: "Crash & server logs", color: Color(red: 1.0, green: 0.45, blue: 0.45))
            }

            NavigationLink {
                ConfigView(server: currentServer)
                    .navigationTitle("Config")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                MenuTile(icon: "slider.horizontal.3", title: "Config", subtitle: "server.properties", color: Color(red: 0.3, green: 0.85, blue: 0.8))
            }

            NavigationLink {
                ServerSettingsView(server: currentServer)
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                MenuTile(icon: "gearshape.fill", title: "Settings", subtitle: "MOTD & RAM", color: Color(white: 0.6))
            }

            // Quick command tile
            NavigationLink {
                QuickCommandView(server: currentServer)
                    .navigationTitle("Run Command")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                MenuTile(icon: "text.cursor", title: "Command", subtitle: "Quick command", color: Color(red: 0.9, green: 0.8, blue: 0.3))
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - WebSocket

    private func setupWebSocket() async {
        guard let url = await appState.client.webSocketURL(serverId: server.id) else { return }
        let ws = ServerWebSocket(serverId: server.id, wsURL: url)
        ws.onStatusChange = { old, new in
            Task { @MainActor in
                notifService.handleStatusChange(serverName: server.name, from: old, to: new)
            }
        }
        ws.connect()
        ws.subscribe(to: .status)
        webSocket = ws
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
            HStack(spacing: 7) {
                if loading {
                    ProgressView().scaleEffect(0.7).tint(.white)
                } else {
                    Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                }
                Text(label).font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
            .background(
                Capsule()
                    .fill(color.opacity(0.2))
                    .overlay(Capsule().strokeBorder(color.opacity(0.5), lineWidth: 1))
            )
            .shadow(color: color.opacity(0.25), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(GlassButtonStyle())
        .disabled(loading)
    }
}

// MARK: - Quick Stat Pill

struct QuickStatPill: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(color.opacity(0.08))
                .overlay(Capsule().strokeBorder(color.opacity(0.15), lineWidth: 1))
        )
    }
}

// MARK: - Menu Tile

struct MenuTile: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(color)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.2))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                    .lineLimit(1)
            }
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.06), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            }
        )
        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Quick Command View

struct QuickCommandView: View {
    let server: ExarotonServer

    @EnvironmentObject var appState: AppState
    @State private var command = ""
    @State private var history: [String] = []
    @State private var isSending = false
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.07, blue: 0.05), Color(red: 0.04, green: 0.05, blue: 0.09)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {

                // History
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        if history.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "text.cursor")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.white.opacity(0.15))
                                Text("Run a server command")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.3))
                                Text("e.g. /say Hello, /op player, /gamemode creative")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.2))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            ForEach(history.indices, id: \.self) { i in
                                HStack(spacing: 8) {
                                    Text(">")
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Color(red: 0.3, green: 0.9, blue: 0.5))
                                    Text(history[i])
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }

                // Input
                HStack(spacing: 10) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(red: 0.3, green: 0.9, blue: 0.5))

                    TextField("Enter command…", text: $command)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(.white)
                        .focused($focused)
                        .submitLabel(.send)
                        .onSubmit { sendCommand() }

                    Button {
                        sendCommand()
                    } label: {
                        if isSending {
                            ProgressView().scaleEffect(0.7).tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(command.isEmpty ? .white.opacity(0.2) : Color(red: 0.3, green: 0.9, blue: 0.5))
                        }
                    }
                    .disabled(command.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .onAppear { focused = true }
    }

    private func sendCommand() {
        let cmd = command.trimmingCharacters(in: .whitespaces)
        guard !cmd.isEmpty else { return }
        history.append(cmd)
        command = ""
        isSending = true
        Task {
            try? await appState.client.executeCommand(serverId: server.id, command: cmd)
            isSending = false
        }
    }
}
