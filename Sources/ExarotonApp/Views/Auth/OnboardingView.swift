import SwiftUI

// MARK: - Onboarding / Login View

struct OnboardingView: View {

    @EnvironmentObject var appState: AppState
    @State private var token = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showToken = false
    @FocusState private var tokenFocused: Bool

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.08, blue: 0.06),
                    Color(red: 0.05, green: 0.16, blue: 0.10),
                    Color(red: 0.03, green: 0.05, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative blobs
            Circle()
                .fill(Color(red: 0.1, green: 0.8, blue: 0.4).opacity(0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: -80, y: -200)

            Circle()
                .fill(Color(red: 0.1, green: 0.4, blue: 0.9).opacity(0.08))
                .frame(width: 250, height: 250)
                .blur(radius: 50)
                .offset(x: 100, y: 200)

            VStack(spacing: 0) {
                Spacer()

                // Logo & Title
                VStack(spacing: 16) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 56, weight: .thin))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.3, green: 1.0, blue: 0.5), Color(red: 0.1, green: 0.7, blue: 1.0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Exaroton")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Manage your Minecraft servers\nfrom anywhere")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.bottom, 48)

                Spacer()

                // Token Input Card
                GlassCard(cornerRadius: 24, padding: 24) {
                    VStack(alignment: .leading, spacing: 16) {

                        Text("API Token")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                            .textCase(.uppercase)
                            .tracking(1)

                        HStack {
                            Group {
                                if showToken {
                                    TextField("Paste your API token", text: $token)
                                } else {
                                    SecureField("Paste your API token", text: $token)
                                }
                            }
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundStyle(.white)
                            .focused($tokenFocused)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                            Button {
                                showToken.toggle()
                            } label: {
                                Image(systemName: showToken ? "eye.slash" : "eye")
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(
                                            tokenFocused
                                            ? Color(red: 0.2, green: 0.9, blue: 0.45).opacity(0.6)
                                            : Color.white.opacity(0.1),
                                            lineWidth: 1.5
                                        )
                                )
                        )
                        .animation(.easeInOut(duration: 0.2), value: tokenFocused)

                        if let err = errorMessage {
                            Label(err, systemImage: "exclamationmark.triangle.fill")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(Color(red: 1.0, green: 0.4, blue: 0.4))
                        }

                        Button {
                            Task { await signIn() }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Image(systemName: "arrow.right.circle.fill")
                                    Text("Connect")
                                        .fontWeight(.semibold)
                                }
                            }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.3, green: 1.0, blue: 0.5),
                                        Color(red: 0.1, green: 0.7, blue: 0.9)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                        }
                        .buttonStyle(GlassButtonStyle())
                        .disabled(token.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                        .opacity(token.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                        .animation(.easeInOut(duration: 0.2), value: token.isEmpty)

                        Link("Get your API token from exaroton.com →",
                             destination: URL(string: "https://exaroton.com/account/")!)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(Color(red: 0.3, green: 0.8, blue: 0.5))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(.horizontal, 20)

                Spacer().frame(height: 40)
            }
        }
        .onTapGesture { tokenFocused = false }
    }

    private func signIn() async {
        let t = token.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        await appState.signIn(token: t)
        isLoading = false
        if appState.accountInfo == nil {
            errorMessage = "Invalid token — please check and try again"
        }
    }
}
