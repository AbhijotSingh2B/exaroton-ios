import SwiftUI

// MARK: - Live Console View

struct ConsoleView: View {

    let server: ExarotonServer
    let webSocket: ServerWebSocket?

    @State private var command = ""
    @State private var autoScroll = true
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {

            // Toolbar
            HStack {
                Label("Live Console", systemImage: "terminal.fill")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()

                Toggle(isOn: $autoScroll) {
                    Text("Auto-scroll")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .toggleStyle(.switch)
                .scaleEffect(0.75, anchor: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Console output
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        if let ws = webSocket, !ws.consolLines.isEmpty {
                            ForEach(Array(ws.consolLines.enumerated()), id: \.offset) { idx, line in
                                ConsoleLineView(line: line)
                                    .id(idx)
                            }
                        } else {
                            Text(server.status.isOnline
                                 ? "Connecting to console stream…"
                                 : "Server is \(server.status.description.lowercased()). Console unavailable.")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.3))
                                .padding(.top, 20)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .background(Color.black.opacity(0.4))
                .onChange(of: webSocket?.consolLines.count) { _, count in
                    guard autoScroll, let count, count > 0 else { return }
                    withAnimation(.linear(duration: 0.1)) {
                        proxy.scrollTo(count - 1, anchor: .bottom)
                    }
                }
            }

            // Command input
            if server.status.isOnline {
                HStack(spacing: 10) {
                    Text(">")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.3, green: 0.9, blue: 0.5))

                    TextField("Enter command…", text: $command)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(.white)
                        .focused($inputFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.send)
                        .onSubmit { sendCommand() }

                    Button {
                        sendCommand()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(command.isEmpty
                                ? Color.white.opacity(0.2)
                                : Color(red: 0.3, green: 0.9, blue: 0.5))
                    }
                    .disabled(command.trimmingCharacters(in: .whitespaces).isEmpty)
                    .animation(.easeInOut(duration: 0.15), value: command.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Color.black.opacity(0.5)
                        .overlay(
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 1),
                            alignment: .top
                        )
                )
            }
        }
        .onAppear {
            webSocket?.subscribe(to: .console, tail: 50)
        }
        .onDisappear {
            webSocket?.unsubscribe(from: .console)
        }
    }

    private func sendCommand() {
        let cmd = command.trimmingCharacters(in: .whitespaces)
        guard !cmd.isEmpty else { return }
        webSocket?.sendCommand(cmd)
        command = ""
    }
}
