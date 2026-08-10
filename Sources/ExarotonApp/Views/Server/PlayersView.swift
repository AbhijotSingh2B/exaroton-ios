import SwiftUI

// MARK: - Players View

struct PlayersView: View {

    let server: ExarotonServer

    @EnvironmentObject var appState: AppState
    @State private var availableLists: [String] = []
    @State private var selectedList: String = "whitelist"
    @State private var playerList: [String]?
    @State private var isLoading = false
    @State private var newPlayerName = ""
    @State private var showAddSheet = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {

            // List picker
            if !availableLists.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableLists, id: \.self) { list in
                            Button {
                                selectedList = list
                                Task { await loadList() }
                            } label: {
                                Text(list.capitalized)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .foregroundStyle(selectedList == list ? .black : .white.opacity(0.6))
                                    .background(
                                        Capsule().fill(selectedList == list
                                            ? Color(red: 0.3, green: 0.9, blue: 0.5)
                                            : Color.white.opacity(0.08))
                                    )
                            }
                            .buttonStyle(GlassButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }

            if let err = errorMessage {
                Text(err)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Color(red: 1, green: 0.4, blue: 0.4))
                    .padding(.horizontal, 16)
            }

            // Player list
            if isLoading {
                Spacer()
                ProgressView().tint(Color(red: 0.3, green: 0.9, blue: 0.5))
                Spacer()
            } else if let list = playerList {
                List {
                    Section {
                        if list.isEmpty {
                            Text("No entries in \(selectedList)")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))
                                .listRowBackground(Color.white.opacity(0.04))
                        } else {
                            ForEach(list, id: \.self) { entry in
                                HStack(spacing: 12) {
                                    AsyncImage(url: URL(string: "https://crafatar.com/avatars/\(entry)?size=32&overlay")) { img in
                                        img.resizable().frame(width: 30, height: 30)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    } placeholder: {
                                        Image(systemName: "person.fill")
                                            .foregroundStyle(.white.opacity(0.3))
                                            .frame(width: 30, height: 30)
                                    }
                                    Text(entry)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.85))
                                }
                                .listRowBackground(Color.white.opacity(0.04))
                            }
                            .onDelete { idx in
                                let toRemove = idx.map { list[$0] }
                                Task { await remove(players: toRemove) }
                            }
                        }
                    } header: {
                        Text("\(list.count) entries")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .tint(Color(red: 0.3, green: 0.9, blue: 0.5))
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            addPlayerSheet
        }
        .task {
            await loadAvailable()
            await loadList()
        }
    }

    // MARK: Add Sheet

    private var addPlayerSheet: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.06, blue: 0.08).ignoresSafeArea()
                VStack(spacing: 20) {
                    TextField("Player name", text: $newPlayerName)
                        .font(.system(size: 16, design: .rounded))
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.07)))
                        .foregroundStyle(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(.horizontal)
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Add to \(selectedList.capitalized)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showAddSheet = false }
                        .tint(.white.opacity(0.5))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        Task {
                            await add(player: newPlayerName)
                            showAddSheet = false
                            newPlayerName = ""
                        }
                    }
                    .tint(Color(red: 0.3, green: 0.9, blue: 0.5))
                    .disabled(newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.height(200)])
        .preferredColorScheme(.dark)
    }

    // MARK: Actions

    private func loadAvailable() async {
        do {
            availableLists = try await appState.client.getAvailablePlayerLists(serverId: server.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadList() async {
        isLoading = true
        defer { isLoading = false }
        do {
            playerList = try await appState.client.getPlayerList(serverId: server.id, list: selectedList)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func add(player: String) async {
        let name = player.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        do {
            try await appState.client.addPlayersToList(serverId: server.id, list: selectedList, players: [name])
            await loadList()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func remove(players: [String]) async {
        do {
            try await appState.client.removePlayersFromList(serverId: server.id, list: selectedList, players: players)
            await loadList()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
