import SwiftUI

// MARK: - Server Settings View (MOTD + RAM)

struct ServerSettingsView: View {

    let server: ExarotonServer

    @EnvironmentObject var appState: AppState
    @State private var motd: String = ""
    @State private var ram: Int = 2
    @State private var originalMOTD: String = ""
    @State private var originalRAM: Int = 2
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var successMessage: String?

    var hasChanges: Bool { motd != originalMOTD || ram != originalRAM }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // MOTD Card
                GlassCard(cornerRadius: 20, padding: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Server MOTD", systemImage: "quote.bubble.fill")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .textCase(.uppercase)
                            .tracking(1)
                            .foregroundStyle(.white.opacity(0.4))

                        TextEditor(text: $motd)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )

                        Text("Shown in the server list below the name")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)

                // RAM Card
                GlassCard(cornerRadius: 20, padding: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Server RAM", systemImage: "memorychip.fill")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .textCase(.uppercase)
                            .tracking(1)
                            .foregroundStyle(.white.opacity(0.4))

                        HStack {
                            Text("\(ram) GB")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(red: 0.3, green: 0.9, blue: 0.5))
                            Spacer()
                        }

                        Slider(value: Binding(
                            get: { Double(ram) },
                            set: { ram = Int($0.rounded()) }
                        ), in: 1...16, step: 1)
                        .tint(Color(red: 0.3, green: 0.9, blue: 0.5))

                        HStack {
                            Text("1 GB").foregroundStyle(.white.opacity(0.3))
                            Spacer()
                            Text("16 GB").foregroundStyle(.white.opacity(0.3))
                        }
                        .font(.system(size: 12, design: .rounded))

                        Text("Changes take effect on next server start")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)

                // Success message
                if let msg = successMessage {
                    Label(msg, systemImage: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.3, green: 0.9, blue: 0.5))
                        .transition(.opacity.combined(with: .scale))
                }

                // Save Button
                Button {
                    Task { await saveSettings() }
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView().tint(.black)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Changes")
                                .fontWeight(.semibold)
                        }
                    }
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        hasChanges
                        ? LinearGradient(
                            colors: [Color(red: 0.3, green: 1.0, blue: 0.5), Color(red: 0.1, green: 0.7, blue: 0.9)],
                            startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.white.opacity(0.15), Color.white.opacity(0.15)],
                            startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                }
                .buttonStyle(GlassButtonStyle())
                .disabled(!hasChanges || isSaving)
                .padding(.horizontal, 16)
                .animation(.easeInOut(duration: 0.2), value: hasChanges)

                Spacer(minLength: 40)
            }
            .padding(.top, 16)
        }
        .task { await loadSettings() }
    }

    private func loadSettings() async {
        isLoading = true
        defer { isLoading = false }
        async let motdResult = (try? await appState.client.getMOTD(serverId: server.id)) ?? ""
        async let ramResult = (try? await appState.client.getRAM(serverId: server.id)) ?? 2
        let (m, r) = await (motdResult, ramResult)
        motd = m
        originalMOTD = m
        ram = r
        originalRAM = r
    }

    private func saveSettings() async {
        isSaving = true
        defer { isSaving = false }
        if motd != originalMOTD {
            try? await appState.client.setMOTD(serverId: server.id, motd: motd)
            originalMOTD = motd
        }
        if ram != originalRAM {
            try? await appState.client.setRAM(serverId: server.id, ram: ram)
            originalRAM = ram
        }
        withAnimation { successMessage = "Settings saved!" }
        try? await Task.sleep(nanoseconds: 2_500_000_000)
        withAnimation { successMessage = nil }
    }
}
