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
