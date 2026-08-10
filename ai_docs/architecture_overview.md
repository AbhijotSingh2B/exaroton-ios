# Exaroton iOS App Architecture

This document provides a high-level overview of the Exaroton iOS App's architecture to help AI assistants navigate and contribute to the codebase efficiently.

## Core Architectural Pattern
The application heavily utilizes the **SwiftUI MVVM (Model-View-ViewModel)** paradigm, combined with the `@MainActor` attribute and modern Swift Concurrency.

### 1. Networking Layer (`Networking/`)
The app interacts with the Exaroton service via two primary components:
- **`ExarotonClient.swift`**: An `actor` that handles all standard REST API requests (starting/stopping servers, reading configs). Because it's an actor, it inherently prevents data races during token rotation or parallel network requests.
- **`ExarotonWebSocket.swift` (`ServerWebSocket`)**: An `@MainActor ObservableObject` that maintains a persistent connection to the server's WebSocket stream. It subscribes to multiple channels (console, stats, heap, tick) and exposes `@Published` properties that views directly bind to.

### 2. State Management (`App/AppState.swift`)
Global application state (like the currently active user, or global navigation path) is managed using SwiftUI's `@EnvironmentObject` or `@StateObject` at the root (`ExarotonApp.swift`).

### 3. Data Models (`Networking/Models/`)
All models parsed from JSON are simple `Codable` structs. We avoid classes for models to enforce value semantics and avoid reference mutation bugs.

## Strict Concurrency Rules
As outlined in `AGENTS.md`:
- Do NOT use `DispatchQueue.main.async`. Use `Task { @MainActor in }` or ensure the class/function is annotated with `@MainActor`.
- Use `.task { ... }` in SwiftUI instead of `.onAppear` when initiating async network calls. This ensures the task is automatically cancelled if the user navigates away before it finishes.

## Real-Time Data Handling
The WebSocket can send hundreds of log lines per second when a server starts. The `ServerWebSocket` uses Combine's `.collect(.byTime(...))` operator to throttle these UI updates to every 200ms. **Never** append directly to a `@Published` array inside a high-frequency loop, as it will cause severe SwiftUI frame drops.
