# Exaroton iOS App Testing Strategy

When adding new features or modifying the network stack, you should write tests to verify functionality. This document outlines the best practices for testing within this specific codebase.

## 1. Mocking the Network Layer
Do **not** perform live network requests in unit tests against the real Exaroton API, as this can trigger rate limits or inadvertently alter a real Minecraft server's state.

Instead, when writing tests for `ExarotonClient`, inject a `URLProtocol` mock into the `URLSession` configuration. This allows you to intercept the outbound requests and return static JSON fixtures.

```swift
// Example Mock Setup
let config = URLSessionConfiguration.ephemeral
config.protocolClasses = [MockURLProtocol.self]
let session = URLSession(configuration: config)
// Initialize the client using this session
```

## 2. Testing Swift Concurrency
Since the app heavily utilizes `async/await` and Actors, your XCTest functions must be marked as `async`.

```swift
func testServerStart() async throws {
    // 1. Arrange (Setup MockURLProtocol to return 200 OK)
    // 2. Act
    try await client.startServer(id: "mock_id")
    // 3. Assert (Verify MockURLProtocol received the correct POST payload)
}
```

## 3. Testing the WebSocket (`ServerWebSocket`)
Testing Combine and WebSockets is notoriously flaky. 
- To test the JSON decoding of `WSMessage`, write isolated unit tests that pass raw JSON strings into the decoder and assert the resulting struct.
- To test the `@Published` state changes, use an `expectation` combined with a `sink` on the publisher, ensuring you wait for the value to settle. Remember that the console logs are throttled by 200ms using `.collect(.byTime())`, so your tests must account for this delay (e.g., using `XCTWaiter`).

## 4. UI Testing
If creating UI tests, ensure you mock the Keychain data at app launch (e.g., by passing launch arguments like `-mockKeychain true`) so the UI tests don't fail immediately at the `OnboardingView`.
