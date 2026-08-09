# Exaroton iOS App

A full-featured native iOS app for managing [Exaroton](https://exaroton.com) Minecraft servers. Built with **SwiftUI** and the **iOS 26 Liquid Glass** design language.

## Features

| Feature | Description |
|---|---|
| 🖥️ Dashboard | Server list with live status indicators |
| ▶️ Controls | Start, Stop, Restart servers |
| 📟 Live Console | Real-time WebSocket console + command input |
| 📊 Stats | Animated RAM & TPS gauges (WebSocket) |
| 👥 Players | Whitelist, ops, bans — add/remove |
| 📁 Files | Directory browser + inline text editor |
| ⚙️ Config | server.properties editor with type-aware inputs |
| 📜 Logs | Server logs viewer + mclo.gs upload |
| 🔔 Notifications | Alerts when server starts, stops, or crashes |
| 💳 Account | Credits balance display |

## Requirements

- iOS 17.0+  (Liquid Glass on iOS 26+, ultraThinMaterial fallback on iOS 17–25)
- An [Exaroton API token](https://exaroton.com/account/)

## Sideloading via AltStore

This app is distributed as an **unsigned IPA**. You need [AltStore](https://altstore.io) to install it.

### Step 1 — Build the IPA

Push to `main` on GitHub. The Actions workflow automatically:
1. Installs XcodeGen
2. Generates the Xcode project
3. Builds an unsigned IPA
4. Uploads it as an Actions artifact

### Step 2 — Download the IPA

Go to your repository → **Actions** → latest workflow run → **Artifacts** → download `ExarotonApp-IPA.zip`

### Step 3 — Install with AltStore

1. Connect your iPhone to your Mac/PC (or use AltStore via Wi-Fi)
2. Open **AltStore** on your computer
3. Drag the `.ipa` file onto the AltStore window, or use **My Apps → +**
4. AltStore signs it with your free Apple ID and installs it
5. On your iPhone: **Settings → VPN & Device Management** → trust your developer certificate

> **Refresh reminder**: With a free Apple ID, apps expire every **7 days**. Open AltStore and tap **Refresh All** to extend.

### Release via Tags

Push a git tag (e.g. `v1.0.0`) to automatically create a GitHub Release with the IPA attached:

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Project Structure

```
ExarotonApp/
├── project.yml                          # XcodeGen spec
├── .github/workflows/build-ipa.yml      # CI build
└── Sources/ExarotonApp/
    ├── App/          ExarotonApp.swift, AppState.swift
    ├── Account/      AccountManager.swift, KeychainManager.swift
    ├── Networking/   ExarotonClient.swift, ExarotonWebSocket.swift
    │   └── Models/   Server, Account, PlayerList, FileInfo, ConfigOption…
    ├── Services/     NotificationService.swift
    ├── Views/
    │   ├── Auth/     OnboardingView
    │   ├── Dashboard/ DashboardView, ServerCardView
    │   ├── Server/   ServerDetailView, ConsoleView, StatsView,
    │   │             PlayersView, LogsView, FilesView,
    │   │             ConfigView, ServerSettingsView
    │   ├── Account/  AccountView
    │   └── Components/ GlassCard, StatusBadge, AnimatedGauge, ConsoleLineView
    └── Resources/    Info.plist, Assets.xcassets
```

## Adding a Second Account (Future)

The architecture is ready for multi-account. To add it:
1. Add `[ExarotonAccount]` storage to `KeychainManager` (new key per account ID)
2. Add `accounts: [ExarotonAccount]` to `AccountManager`
3. Add an account switcher UI in `AccountView`
4. `ExarotonClient` already reads `activeAccount` from the manager — no changes needed there
