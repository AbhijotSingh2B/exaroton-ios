import SwiftUI

@main
struct ExarotonApp: App {

    @StateObject private var appState    = AppState()
    @StateObject private var notifService = NotificationService()

    var body: some Scene {
        WindowGroup {
            ContentRootView()
                .environmentObject(appState)
                .environmentObject(notifService)
                .preferredColorScheme(.dark)
                .onAppear {
                    notifService.requestPermission()
                }
        }
    }
}

// MARK: - Root Router

struct ContentRootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isAuthenticated {
                DashboardView()
            } else {
                OnboardingView()
            }
        }
        .animation(.spring(duration: 0.4), value: appState.isAuthenticated)
    }
}
