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

## Sideloading & Beta Access (SideStore)

This app is distributed as an **unsigned IPA**. We natively support [SideStore](https://sidestore.io) for untethered, on-device sideloading and Over-The-Air (OTA) updates!

### Step 1 — Add the Source

We automatically publish our beta releases to a SideStore-compatible source JSON. 
Add this URL to your SideStore sources:
`https://raw.githubusercontent.com/AbhijotSingh2B/exaroton-ios/development/sidestore.json`

*(Note: Ensure you are tracking the `development` branch for the latest beta updates!)*

### Step 2 — Install & Update

1. Open **SideStore** on your iPhone or iPad.
2. Navigate to the **Sources** tab and add the URL above.
3. Find **Exaroton** and tap **Install**.
4. Whenever we push a new beta, SideStore will notify you, allowing you to update directly from your device!

> **Refresh reminder**: With a free Apple ID, sideloaded apps expire every **7 days**. Open SideStore and tap **Refresh** while connected to the SideStore WireGuard VPN to extend it without a computer.

### AltStore Fallback

If you prefer [AltStore](https://altstore.io), you can still manually download the `ExarotonApp-IPA.zip` from our GitHub Actions artifacts or Releases tab and install it manually via your computer.

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
