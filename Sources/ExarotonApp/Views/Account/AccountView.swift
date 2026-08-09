import SwiftUI

// MARK: - Account View

struct AccountView: View {

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notifService: NotificationService
    @Environment(\.dismiss) var dismiss
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.06, blue: 0.08).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        // Profile header
                        GlassCard(cornerRadius: 22, padding: 24) {
                            VStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(red: 0.2, green: 0.9, blue: 0.5), Color(red: 0.1, green: 0.5, blue: 0.9)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 72, height: 72)
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(.white)
                                }

                                VStack(spacing: 4) {
                                    Text(appState.accountInfo?.name ?? "Unknown")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                    Text(appState.accountInfo?.email ?? "")
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.5))
                                }

                                // Credits
                                HStack(spacing: 8) {
                                    Image(systemName: "creditcard.fill")
                                        .foregroundStyle(Color(red: 0.3, green: 1.0, blue: 0.6))
                                    Text("\(String(format: "%.1f", appState.accountInfo?.credits ?? 0.0)) credits")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(Color(red: 0.15, green: 0.9, blue: 0.45).opacity(0.15))
                                )
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 20)

                        // Notification status
                        GlassCard(cornerRadius: 18, padding: 16) {
                            HStack {
                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color(red: 0.9, green: 0.6, blue: 0.2))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Notifications")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                    Text(notifStatusText)
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                Spacer()
                                if notifService.authorizationStatus != .authorized {
                                    Button("Enable") {
                                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(Color(red: 0.3, green: 0.9, blue: 0.5))
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Sign Out
                        Button(role: .destructive) {
                            showSignOutAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                                    .fontWeight(.semibold)
                            }
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(Color(red: 1.0, green: 0.4, blue: 0.4))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(GlassButtonStyle())
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .tint(Color(red: 0.3, green: 0.9, blue: 0.5))
                }
            }
            .alert("Sign Out?", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) {
                    appState.signOut()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your API token will be removed from this device.")
            }
            .onAppear {
                notifService.refreshStatus()
            }
        }
    }

    private var notifStatusText: String {
        switch notifService.authorizationStatus {
        case .authorized:       return "Enabled — you'll be notified on server changes"
        case .denied:           return "Disabled — tap Enable to allow notifications"
        case .notDetermined:    return "Not yet requested"
        default:                return "Unknown status"
        }
    }
}
