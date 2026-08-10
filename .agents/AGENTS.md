# Project Rules & High-Quality Code Control

## Git Workflow
- **Branching:** Always push to a `development` branch instead of `main`. Do not commit directly to `main`.

## Swift & Architecture Guidelines
- **No Force Unwrapping:** Never use `!` to force unwrap optionals. Handle optionals safely with `guard let` or `if let`. The only exception is for hardcoded, static `URL(string:)` definitions.
- **Modern Concurrency:** Use Swift Concurrency (`async/await`, `Task`, `actor`) instead of legacy completion handlers wherever possible.
- **Task Lifecycles:** Tie asynchronous work to a view's lifecycle using the `.task { ... }` modifier rather than manual `Task { ... }` blocks inside `.onAppear`. This guarantees automatic cancellation when the view disappears and prevents memory leaks.
- **State Management:** When passing `ObservableObject` instances to child views, always declare them with `@ObservedObject` (or `@EnvironmentObject`) to ensure the view updates when properties change. Never pass them as a simple `let` constant.
- **Memory Management:** Strictly use `[weak self]` in closures (e.g., Timers, combine sinks, legacy callbacks) that capture `self` to prevent retain cycles.
- **Throttling Data Streams:** For high-frequency data updates (like WebSocket logs), always implement a buffering or throttling mechanism (e.g., Combine's `.collect(.byTime(...))`) before updating `@Published` state arrays to prevent SwiftUI from freezing.

## UI / UX
- **Apple HIG Compliance:** Adhere to Apple's Human Interface Guidelines. For example, never request user permissions (like Push Notifications) immediately on app launch; wait for contextual user interaction.

## Release & Distribution
- **GitHub Releases:** Follow Semantic Versioning (`vX.Y.Z`). Always write structured release notes and generate releases directly from a pushed Git Tag. Use GitHub Actions to automate the building of `.ipa` files and attach them to the release along with a SHA256 checksum.
- **SideStore Updates:** To maintain support for third-party sideloading stores like SideStore, any GitHub release must automate the updating of the `sidestore.json` file. The action should inject the new version number, release date, and direct `.ipa` download URL into the JSON source file, so users receive over-the-air updates.

## AI Agent Behavior & Anti-Hallucination
- **Verify Before Writing:** Do not assume the existence of functions, models, or views. Always use `grep_search` or `list_dir` to verify the exact names of files, properties, and methods before attempting to call or edit them.
- **Strict Pattern Matching:** When adding new features, strictly copy the architecture and styling patterns already present in the codebase (e.g., existing `GlassCard` usage, established `ExarotonClient` request formatting) rather than inventing new paradigms.
- **Do Not Guess APIs:** If a specific Apple framework or third-party SDK behavior is ambiguous, do not guess the API surface. Write a compile-check, read the headers, or ask the user for clarification.
- **Fail Fast:** If a requirement is underspecified, stop and ask the user for clarification rather than hallucinating a complex and potentially incorrect implementation.
