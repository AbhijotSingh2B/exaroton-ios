import SwiftUI
import Combine

// MARK: - App State (Global)

@MainActor
final class AppState: ObservableObject {

    // MARK: Published

    @Published var accountInfo: ExarotonAccountInfo?
    @Published var servers: [ExarotonServer] = []
    @Published var isLoadingServers = false
    @Published var isLoadingAccount = false
    @Published var errorMessage: String?

    // MARK: Account

    let accountManager: AccountManager

    var isAuthenticated: Bool { accountManager.activeAccount != nil }

    // MARK: Networking

    let client: ExarotonClient

    // MARK: Init

    init() {
        let mgr = AccountManager()
        self.accountManager = mgr
        self.client = ExarotonClient(accountManager: mgr)
    }

    // MARK: Public

    func signIn(token: String, name: String = "My Account") async {
        accountManager.setActiveAccount(ExarotonAccount(displayName: name, token: token))
        await loadAll()
    }

    func signOut() {
        accountManager.removeActiveAccount()
        servers = []
        accountInfo = nil
    }

    func loadAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadAccountInfo() }
            group.addTask { await self.loadServers() }
        }
    }

    func loadAccountInfo() async {
        isLoadingAccount = true
        defer { isLoadingAccount = false }
        do {
            accountInfo = try await client.getAccount()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadServers() async {
        isLoadingServers = true
        defer { isLoadingServers = false }
        do {
            servers = try await client.getServers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Update single server in list (from WebSocket)

    func updateServer(_ server: ExarotonServer) {
        if let idx = servers.firstIndex(where: { $0.id == server.id }) {
            servers[idx] = server
        }
    }
}
