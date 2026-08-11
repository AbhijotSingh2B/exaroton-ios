# Future Goals Implementation Research

This document details the exact APIs, system frameworks, Swift 6 architectural changes, and **potential bugs/pitfalls** required to implement the remaining future goals for the Exaroton iOS App.

## 1. Multi-Account Support

**Objective:** Allow users to log into multiple Exaroton accounts and seamlessly switch between them.
**Frameworks:** `Security` (Keychain), `Foundation` (UserDefaults)

### Relevant APIs & Code Changes
- **Keychain Structure:** Instead of storing a single API token under the key `exaroton_api_token`, we need to serialize an array of `ExarotonAccount` structs and store them as a JSON payload, or use the Exaroton `Profile ID` as the keychain Account identifier.
  ```swift
  struct ExarotonAccount: Codable, Identifiable, Hashable {
      var id: String // Exaroton Profile ID
      var name: String
      var email: String
      var token: String
  }
  ```
- **KeychainManager Updates:**
  - `saveAccount(_ account: ExarotonAccount)`: Encodes the array and saves it.
  - `getAccounts() -> [ExarotonAccount]`: Retrieves all saved accounts.
  - `deleteAccount(id: String)`: Removes an account from the array.
- **AccountManager Updates:**
  - Introduce `@Published var accounts: [ExarotonAccount] = []`
  - Introduce `@Published var activeAccountId: String?`
  - When `activeAccountId` changes, it persists the choice to `UserDefaults.standard.set(id, forKey: "ActiveAccountID")`.
- **ExarotonClient Concurrency:** 
  - `ExarotonClient` is an `actor`. It must dynamically fetch the active token via `await accountManager.activeAccount?.token`.

### ⚠️ Possible Bugs & Pitfalls
- **Keychain Migration Crash:** Existing users have a plain string saved under the `exaroton_api_token` Keychain key. If the new `KeychainManager` attempts to decode this string as a JSON array of `ExarotonAccount`, the app will crash. We must implement a migration block that detects the old string, creates an `ExarotonAccount` from it, and re-saves it as JSON.
- **Stale Tokens in Memory:** If any view or class creates a copy of the API token on `init()` rather than dynamically awaiting it from `AccountManager`, switching accounts will not affect that view, causing data leaks between accounts or 401 Unauthorized errors.

---

## 2. Widgets & Live Activities

**Objective:** Provide at-a-glance server status on the Home Screen, and live start/stop progress via the Dynamic Island.
**Frameworks:** `WidgetKit`, `ActivityKit`, `SwiftUI`, `AppIntents`

### Relevant APIs & Code Changes
- **App Groups:** Both the main app and the Widget Extension must share an App Group (e.g., `group.com.abhijotsingh2b.exaroton`). This allows the Widget to read the Keychain and `UserDefaults` to know which account is active.
- **WidgetKit (Static Widget):**
  - Implement a `TimelineProvider`. In the `getTimeline` function, instantiate `ExarotonClient`, call `getServers()`, and create a `Timeline` refreshing every 30-60 minutes (`.after(nextRefreshDate)`).
- **ActivityKit (Live Activities):**
  - **Start:** When a user taps "Start Server" in the main app, initiate a Live Activity using `Activity.request()`.
  - **Update:** When the WebSocket pushes a `status` change, call `await activity.update(using: newState)`.
  - **End:** When status reaches `1` (ONLINE) or `0` (OFFLINE), call `await activity.end(using: finalState)`.

### ⚠️ Possible Bugs & Pitfalls
- **App Group Mismatch:** If the App Group identifier is mistyped in either the Widget target or the Main App target capabilities, the widget's `UserDefaults` will be completely isolated. The widget will constantly display a "Please log in" state because it cannot see the token.
- **Exaroton API Rate Limiting (429):** Widgets are allowed by iOS to refresh quite frequently. However, if our `TimelineProvider` schedules a refresh every 5 minutes, Exaroton's strict API rate limits will block the user's IP, breaking the main app as well. We must strictly enforce a minimum 15-minute refresh interval.
- **Orphaned Live Activities:** If the user force-closes the app while a server is starting, the WebSocket dies and the Live Activity gets stuck in the Dynamic Island forever. We must implement `ActivityKit` background task handling or set an absolute expiration date for the activity.

---

## 3. Siri & App Intents

**Objective:** Allow users to use Siri ("Hey Siri, start my Exaroton server") and the Shortcuts app.
**Frameworks:** `AppIntents`

### Relevant APIs & Code Changes
- **AppIntents:** Define a `StartServerIntent` struct conforming to `AppIntent`.
- **AppShortcutsProvider:** Register standard phrases so users don't have to manually create a shortcut in the Shortcuts app.
  ```swift
  struct ExarotonShortcuts: AppShortcutsProvider {
      static var appShortcuts: [AppShortcut] {
          // Register intent with phrases
      }
  }
  ```

### ⚠️ Possible Bugs & Pitfalls
- **Swift 6 Concurrency Violations (Crashes):** `AppIntent.perform()` executes on a background thread. If the intent attempts to modify the `DashboardViewModel` (an `@MainActor` ObservableObject) directly to reflect the server starting, Swift 6 will trigger a runtime trap/crash. State updates must be strictly dispatched to `@MainActor`.
- **Memory Leaks:** App Intents instantiated by the system in the background might instantiate new `ExarotonClient` objects. If they attach to a WebSocket and don't cleanly close it before `perform()` returns, it will leak background tasks until iOS terminates the extension.

---

## 4. Biometric Authentication

**Objective:** Require Face ID / Touch ID before performing destructive actions (Stop, Restart, Edit Configs).
**Frameworks:** `LocalAuthentication`

### Relevant APIs & Code Changes
- **LAContext Implementation:** Use `LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, ...)` to gate API calls.

### ⚠️ Possible Bugs & Pitfalls
- **Missing `NSFaceIDUsageDescription`:** If this key is omitted from the `Info.plist`, the app will instantly crash without warning the exact microsecond `LAContext` is invoked.
- **Main Thread Blockage:** `LAContext.evaluatePolicy` completes on a background queue. If you attempt to update a SwiftUI loading spinner or dismiss a sheet from its completion handler without explicitly wrapping it in `Task { @MainActor in }` or `DispatchQueue.main.async`, it will cause purple UI warnings and visual stuttering.

---

## 5. iPadOS & macOS Optimization

**Objective:** Utilize the large screen real estate better than a stretched iPhone app.
**Frameworks:** `SwiftUI`

### Relevant APIs & Code Changes
- **NavigationSplitView:** Upgrade `DashboardView.swift` to use `NavigationSplitView` on iPad.

### ⚠️ Possible Bugs & Pitfalls
- **Lost Navigation State:** On iPhone (`NavigationStack`), navigating pushes a view onto the stack. On iPad (`NavigationSplitView`), it simply updates a `@State` selection variable in the sidebar. If the view is poorly structured, rotating the iPad (or resizing the macOS window) can cause SwiftUI to destroy the SplitView and rebuild the Stack, instantly kicking the user out of the server detail view back to the root list.
- **List Selection Glitches:** The `selection:` binding on a SwiftUI `List` relies heavily on `Hashable`. If the `ExarotonServer` struct changes (e.g., status flips from Offline to Starting), its Hash value changes. This can cause the List to suddenly "deselect" the server on iPad while the user is looking at it. The selection binding must be the stable string ID, not the full server object.

---

## 6. Log Filtering & Search

**Objective:** Allow users to filter server logs by severity (INFO, WARN, ERROR) and text search.
**Frameworks:** `Foundation` (Regex), `SwiftUI` (Searchable)

### Relevant APIs & Code Changes
- **Background Parsing:** String splitting and Regex matching on massive log files must be done using `Task.detached`.

### ⚠️ Possible Bugs & Pitfalls
- **Out of Memory (OOM) Jetsam Kills:** Minecraft server logs can easily exceed 50MB of text. If we load the raw string into memory, split it into an array of 500,000 strings, and map that into 500,000 `LogLine` structs, iOS will instantly terminate the app due to memory pressure. We must truncate the log fetch (using the `tail` parameter) or implement pagination.
- **Main Thread Watchdog (Exit Code 8b3):** If we perform complex Regex capture groups synchronously on the Main Actor, the app will freeze for 3-5 seconds. The iOS Watchdog timer will kill the app for being unresponsive.
- **Regex Backtracking Limits:** User-generated Minecraft logs (from plugins) can be incredibly malformed. A poorly written Regex pattern trying to parse `[23:44:12] [Server thread/INFO]` can experience catastrophic backtracking on a malformed line, pegging CPU usage to 100% permanently. We must use Swift's modern Regex Builder or non-greedy patterns (`.*?`).
