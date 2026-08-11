# Advanced Integrations & Future Scaling

This document explores advanced integrations and modern architectural shifts we can implement to push the Exaroton app beyond its initial scope.

## 1. Swift 17 `@Observable` Migration
Our app's deployment target in `project.yml` is **iOS 17.0**. This means we can completely drop the legacy `ObservableObject` and `@Published` property wrappers in favor of the new `@Observable` macro.

### Why Migrate?
- **Granular Rendering:** With `ObservableObject`, if a single `@Published` array updates (like the WebSocket logs), the *entire* view hierarchy re-renders. With `@Observable`, SwiftUI only re-renders the specific `Text` or `View` that explicitly reads the changed property. This will drastically improve the performance of our real-time WebSocket dashboard.
- **No Boilerplate:** We can replace `@StateObject` with standard `@State`, and `@EnvironmentObject` with `@Environment`.

**Migration Example for `ServerWebSocket`:**
```swift
import Observation

// Before: class ServerWebSocket: ObservableObject { @Published var logs = [] }
@Observable 
@MainActor 
class ServerWebSocket {
    var logs: [String] = []
    var currentTPS: Double = 20.0
    var status: Int = 0
}
```

## 2. Minecraft Server Management Protocol (MSMP)
Starting in Minecraft Java 1.21.9+, Mojang introduced the **Minecraft Server Management Protocol** (MSMP), which uses JSON-RPC 2.0 over WebSockets. The Exaroton API recently exposed this via their `management` stream.

### Capabilities
- **Zero-Downtime Modifications:** We can dynamically change `gamerules`, manage the allowlist, and kick/ban players *without* restarting the server.
- **Real-Time Notifications:** The server pushes `notification` events when a player joins, leaves, or sends a chat message.

### Implementation Strategy
We can add a new `ManagementViewModel` that subscribes to the `management` stream:
```json
// Subscription Payload
{"stream": "management", "type": "start"}

// Example: Sending a Request to change a gamerule
{
  "stream": "management", 
  "type": "request", 
  "data": {
    "id": "req-123", 
    "method": "minecraft:server/gamerule/set", 
    "params": {"name": "keepInventory", "value": true}
  }
}
```

## 3. macOS Menu Bar App (`MenuBarExtra`)
Since the project supports Mac Catalyst and Apple Silicon Macs, we can build a lightweight "Menu Bar Only" companion app.

### Implementation Strategy
Using the `MenuBarExtra` API (available in macOS 13+ / iOS 17+ via Catalyst bridging), we can put the Exaroton server status directly in the user's Mac menu bar.
```swift
@main
struct ExarotonApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
        }
        
        #if os(macOS)
        MenuBarExtra("Exaroton Status", systemImage: "server.rack") {
            MenuBarStatusView()
        }
        .menuBarExtraStyle(.window)
        #endif
    }
}
```
*Note: True native `MenuBarExtra` behavior on Catalyst sometimes requires AppKit bridging plugins, but native Apple Silicon builds support it out of the box.*

## 4. Automating SideStore Distribution (`sidestore.json`)
To achieve the user's goal of over-the-air SideStore updates, our GitHub Actions must automatically generate a `sidestore.json` source file.

### Schema Requirements
The JSON file must conform to the official [SideStore Source Schema](https://github.com/SideStore/sidestore-source-types/raw/main/schema.json).
Our GitHub Action should run a Python or Bash script during release that outputs a file like this:

```json
{
  "$schema": "https://github.com/SideStore/sidestore-source-types/raw/main/schema.json",
  "name": "Exaroton Unofficial",
  "identifier": "com.exaroton.ios",
  "apps": [
    {
      "name": "Exaroton",
      "bundleIdentifier": "com.exaroton.ios",
      "version": "1.0.1",
      "versionDate": "2026-08-11T12:00:00Z",
      "size": 15482910,
      "downloadURL": "https://github.com/YOUR_REPO/releases/download/v1.0.1/Exaroton.ipa",
      "localizedDescription": "Manage your Exaroton servers.",
      "iconURL": "https://raw.githubusercontent.com/YOUR_REPO/main/icon.png"
    }
  ]
}
```
When users add this JSON file's raw URL to their SideStore app on their iPhone, they will receive a push notification whenever we publish a new GitHub Release!
