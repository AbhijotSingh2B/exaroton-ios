import Foundation

// MARK: - Exaroton Account (stored credential)

/// Represents a saved Exaroton account/API token.
/// Future multi-account support: store an array of these in Keychain
/// and add selection UI — the protocol + manager already supports it.
struct ExarotonAccount: Codable, Identifiable, Equatable {
    let id: String          // UUID for local identification
    var displayName: String // User-facing name, e.g. "My Server Account"
    var token: String       // API Bearer token

    init(id: String = UUID().uuidString, displayName: String = "My Account", token: String) {
        self.id = id
        self.displayName = displayName
        self.token = token
    }
}

// MARK: - Account Store Protocol
// Conforming to a protocol makes it easy to swap in a multi-account
// implementation later without touching any view or networking code.

protocol AccountStoring: ObservableObject {
    var activeAccount: ExarotonAccount? { get }
    func setActiveAccount(_ account: ExarotonAccount)
    func removeActiveAccount()
}

// MARK: - Account Manager

@MainActor
final class AccountManager: AccountStoring {

    @Published private(set) var activeAccount: ExarotonAccount?

    init() {
        load()
    }

    // MARK: Public API

    func setActiveAccount(_ account: ExarotonAccount) {
        activeAccount = account
        persist(account)
    }

    func removeActiveAccount() {
        activeAccount = nil
        KeychainManager.delete(forKey: KeychainManager.activeTokenKey)
        KeychainManager.delete(forKey: KeychainManager.activeAccountNameKey)
    }

    // MARK: Private

    private func load() {
        guard
            let token = try? KeychainManager.load(forKey: KeychainManager.activeTokenKey)
        else { return }
        let name = (try? KeychainManager.load(forKey: KeychainManager.activeAccountNameKey)) ?? "My Account"
        activeAccount = ExarotonAccount(displayName: name, token: token)
    }

    private func persist(_ account: ExarotonAccount) {
        try? KeychainManager.save(token: account.token, forKey: KeychainManager.activeTokenKey)
        try? KeychainManager.save(token: account.displayName, forKey: KeychainManager.activeAccountNameKey)
    }
}
