import SwiftUI

// MARK: - Config Files View

struct ConfigView: View {

    let server: ExarotonServer

    @EnvironmentObject var appState: AppState
    @State private var configFile: ConfigFile?
    @State private var editedValues: [String: String] = [:]
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    // server.properties is the main config file
    let fileName = "server.properties"

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {

                if isLoading {
                    ProgressView()
                        .tint(Color(red: 0.3, green: 0.9, blue: 0.5))
                        .padding(.top, 40)
                } else if let err = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color(red: 1, green: 0.6, blue: 0.2))
                        Text(err)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                } else if let config = configFile {
                    ForEach(config.options) { option in
                        ConfigOptionRow(
                            option: option,
                            value: Binding(
                                get: { editedValues[option.key] ?? option.value },
                                set: { editedValues[option.key] = $0 }
                            )
                        )
                    }
                }

                if !editedValues.isEmpty {
                    Button {
                        Task { await saveConfig() }
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView().tint(.black)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save \(editedValues.count) Change\(editedValues.count == 1 ? "" : "s")")
                                    .fontWeight(.semibold)
                            }
                        }
                        .font(.system(size: 16, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.3, green: 1.0, blue: 0.5), Color(red: 0.1, green: 0.7, blue: 0.9)],
                                startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                    }
                    .buttonStyle(GlassButtonStyle())
                    .padding(.horizontal, 16)
                    .disabled(isSaving)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if let msg = successMessage {
                    Label(msg, systemImage: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.3, green: 0.9, blue: 0.5))
                }

                Spacer(minLength: 40)
            }
            .padding(.top, 12)
        }
        .task { await loadConfig() }
        .animation(.spring(duration: 0.3), value: editedValues.isEmpty)
    }

    private func loadConfig() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            configFile = try await appState.client.getConfigOptions(serverId: server.id, file: fileName)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveConfig() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await appState.client.updateConfigOptions(serverId: server.id, file: fileName, options: editedValues)
            editedValues = [:]
            withAnimation { successMessage = "Config saved!" }
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation { successMessage = nil }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Config Option Row

struct ConfigOptionRow: View {
    let option: ConfigOption
    @Binding var value: String

    var isEdited: Bool { value != option.value }

    var body: some View {
        GlassCard(cornerRadius: 16, padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(option.label ?? option.key)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    if isEdited {
                        Text("Modified")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(Color(red: 0.9, green: 0.7, blue: 0.2).opacity(0.2))
                            )
                            .foregroundStyle(Color(red: 0.9, green: 0.7, blue: 0.2))
                    }
                }

                if let doc = option.documentation {
                    Text(doc)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(2)
                }

                // Input based on type
                if let opts = option.options, !opts.isEmpty {
                    // Picker
                    Picker("", selection: $value) {
                        ForEach(opts, id: \.self) { opt in
                            Text(opt).tag(opt)
                        }
                    }
                    .pickerStyle(.segmented)
                    .colorMultiply(Color(red: 0.3, green: 0.9, blue: 0.5))
                } else if option.valueType == "boolean" {
                    Toggle(isOn: Binding(
                        get: { value.lowercased() == "true" },
                        set: { value = $0 ? "true" : "false" }
                    )) { EmptyView() }
                    .tint(Color(red: 0.3, green: 0.9, blue: 0.5))
                } else {
                    TextField(option.key, text: $value)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(isEdited
                                            ? Color(red: 0.9, green: 0.7, blue: 0.2).opacity(0.5)
                                            : Color.clear,
                                            lineWidth: 1)
                                )
                        )
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                // Key label
                Text(option.key)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.2))
            }
        }
        .padding(.horizontal, 16)
        .animation(.easeInOut(duration: 0.15), value: isEdited)
    }
}
