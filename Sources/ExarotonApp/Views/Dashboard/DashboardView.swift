import SwiftUI

// MARK: - Dashboard View

struct DashboardView: View {

    @EnvironmentObject var appState: AppState
    @State private var showAccount = false
    @State private var isAnimating = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Deep Midnight Background
                LinearGradient(
                    colors: [
                        Color(red: 0.01, green: 0.015, blue: 0.03),
                        Color(red: 0.02, green: 0.03, blue: 0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Animated Fluid Glows
                ZStack {
                    Circle()
                        .fill(Color(red: 0.1, green: 0.7, blue: 0.4).opacity(0.12))
                        .frame(width: 450, height: 450)
                        .blur(radius: 120)
                        .offset(x: isAnimating ? 80 : -50, y: isAnimating ? -100 : -250)
                    
                    Circle()
                        .fill(Color(red: 0.2, green: 0.4, blue: 0.9).opacity(0.1))
                        .frame(width: 400, height: 400)
                        .blur(radius: 100)
                        .offset(x: isAnimating ? -80 : 50, y: isAnimating ? 200 : 100)
                }
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                        isAnimating = true
                    }
                }

                ScrollView {
                    LazyVStack(spacing: 14) {

                        // Account header card
                        accountHeaderSection

                        // Section label
                        HStack {
                            Text("Your Servers")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .textCase(.uppercase)
                                .tracking(1.5)
                                .foregroundStyle(
                                    LinearGradient(colors: [.white.opacity(0.7), .white.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                            Spacer()
                            Text("\(appState.servers.count)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.3))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.white.opacity(0.05)))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                        // Server list
                        if appState.isLoadingServers && appState.servers.isEmpty {
                            loadingCards
                        } else if appState.servers.isEmpty {
                            emptyState
                        } else {
                            ForEach(appState.servers) { server in
                                NavigationLink {
                                    ServerDetailView(server: server)
                                } label: {
                                    ServerCardView(server: server)
                                        .padding(.horizontal, 16)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(.top, 8)
                }
                .refreshable {
                    await appState.loadAll()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "server.rack")
                            .foregroundStyle(Color(red: 0.3, green: 0.9, blue: 0.5))
                        Text("Exaroton")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAccount = true
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color(red: 0.3, green: 0.9, blue: 0.5))
                    }
                }
            }
            .sheet(isPresented: $showAccount) {
                AccountView()
            }
        }
        .task {
            await appState.loadAll()
        }
    }

    // MARK: Sub-views

    private var accountHeaderSection: some View {
        GlassCard(cornerRadius: 20, padding: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.9, blue: 0.5), Color(red: 0.1, green: 0.5, blue: 0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(appState.accountInfo?.name ?? "Loading…")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(appState.accountInfo?.email ?? "")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                // Credits chip
                if let credits = appState.accountInfo?.credits {
                    VStack(spacing: 2) {
                        Text(String(format: "%.1f", credits))
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(red: 0.3, green: 1.0, blue: 0.6))
                            .shadow(color: Color(red: 0.3, green: 1.0, blue: 0.6).opacity(0.4), radius: 6, x: 0, y: 0)
                        Text("credits")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var loadingCards: some View {
        ForEach(0..<3, id: \.self) { _ in
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .frame(height: 110)
                .shimmer()
                .padding(.horizontal, 16)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "server.rack")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(.white.opacity(0.2))
            Text("No servers found")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
            Text("Add a server at exaroton.com")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.white.opacity(0.25))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
