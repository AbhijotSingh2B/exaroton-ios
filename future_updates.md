# Future Updates & Tech Debt

This document tracks identified architectural issues, QoL improvements, and technical debt that should be addressed in future updates to maintain strict compliance with `AGENTS.md`.

## 1. Modern Swift Concurrency Migration
The codebase currently has a few violations of the "Modern Concurrency" rule (which mandates the use of `async/await` and `Task` over legacy completion handlers and GCD).

- **`NotificationService.swift`**: 
  - **Issue:** Uses legacy completion handlers for `UNUserNotificationCenter.requestAuthorization` and `getNotificationSettings`.
  - **Fix:** Rewrite `requestPermission()` and `refreshStatus()` to be `async` functions utilizing `try await center.requestAuthorization(...)` and `await center.notificationSettings()`.

- **`ExarotonWebSocket.swift`**: 
  - **Issue:** The `startPing()` method relies on the legacy Foundation `Timer.scheduledTimer` closure to keep the WebSocket alive.
  - **Fix:** Replace the `Timer` with an explicitly retained `pingTask: Task<Void, Never>?` that runs a continuous `Task.sleep` loop, cancelling cleanly when `disconnect()` is called.

- **`ServerDetailView.swift`**: 
  - **Issue:** The "copy IP address" button relies on legacy `DispatchQueue.main.asyncAfter` to reset the checkmark icon after 1.5 seconds.
  - **Fix:** Replace the GCD call with a detached `Task { try? await Task.sleep(nanoseconds: 1_500_000_000) }` block that ties cleanly into the SwiftUI lifecycle and avoids unsafe closures.

## 2. Feature Enhancements & QoL Improvements
Based on modern iOS capabilities and the Exaroton API, the following features should be prioritized for future updates:

- **Multi-Account Support**: As outlined in the `README.md`, implement account switching in `AccountView` by utilizing `KeychainManager` to store multiple `[ExarotonAccount]` objects.
- **Widgets & Live Activities**: Introduce Home Screen and Lock Screen widgets to monitor server status and player counts at a glance. Use Live Activities (Dynamic Island) to track server startup/shutdown progress in real-time.
- **Siri & App Intents Integration**: Add App Intents to allow users to start, stop, or restart their servers using Siri voice commands or the Apple Shortcuts app.
- **Biometric Authentication (Face ID / Touch ID)**: Add an optional layer of security using `LocalAuthentication` for app launch or destructive actions (e.g., stopping the server, editing critical config files).
- **iPadOS & macOS Optimization**: Update the UI to utilize `NavigationSplitView` for a true multi-column layout on iPad and Mac (via Mac Catalyst or native SwiftUI for macOS), which will significantly improve the file manager and console experience on larger screens.
- **Log Filtering & Search**: Implement a search bar and severity filters (Info, Warning, Error) in `LogsView` to make parsing large server logs easier on mobile devices.
