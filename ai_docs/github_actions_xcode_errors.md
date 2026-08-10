# Troubleshooting Xcode Compilation in GitHub Actions

Since this project relies on GitHub Actions to compile the unsigned `.ipa` for SideStore releases, you may encounter `xcodebuild` errors when running the CI pipeline. This document outlines the most common causes and how to resolve them.

## 1. Code Signing & Provisioning Errors
**The Error:** `xcodebuild` fails with "No profile for team '...' matching '...' found" or `errSecInternalComponent`.
**The Cause:** GitHub Actions runners do not have your personal Apple Developer certificates or provisioning profiles installed.
**The Fix:** Since we are distributing an *unsigned* IPA for SideStore, ensure that the GitHub Action explicitly disables code signing during the archive step. Pass the following flags to the `xcodebuild` command in your `.yml` workflow:
```bash
CODE_SIGNING_ALLOWED=NO \
CODE_SIGN_IDENTITY="" \
CODE_SIGNING_REQUIRED=NO \
CODE_SIGN_ENTITLEMENTS=""
```

## 2. Xcode Version Mismatches
**The Error:** "Cannot find type '...' in scope" (when the type exists in a newer iOS SDK) or Swift compiler crashes.
**The Cause:** The `macos-latest` GitHub runner might default to an older version of Xcode than you are using locally.
**The Fix:** Force the workflow to use a specific version of Xcode by adding a step before compilation:
```yaml
- name: Select Xcode Version
  run: sudo xcode-select -switch /Applications/Xcode_15.2.app
```
*(Check the official GitHub Actions virtual environments page for available Xcode paths).*

## 3. Missing Dependencies (Swift Package Manager)
**The Error:** "Missing module map file" or "No such module 'X'".
**The Cause:** SPM sometimes fails to resolve packages correctly in CI due to network timeouts or missing `Package.resolved` files.
**The Fix:** 
1. Ensure the `xcodebuild` command includes the `-resolvePackageDependencies` flag in a separate step before building.
2. If using XcodeGen (as per this project's `project.yml`), make sure you run `xcodegen generate` before calling `xcodebuild`, so the `.xcodeproj` is fully populated with the package links.

## 4. Destination / SDK Errors
**The Error:** "xcodebuild: error: Unable to find a destination matching the provided destination specifier".
**The Cause:** You told `xcodebuild` to build for a specific simulator (e.g., `name=iPhone 15 Pro`), but that exact simulator isn't installed on the GitHub runner.
**The Fix:** Build for the generic iOS device platform rather than a specific simulator, unless you are running UI tests.
```bash
-destination "generic/platform=iOS"
```

## 5. Caching Issues (Derived Data)
**The Error:** Bizarre compilation errors that don't occur locally, often after renaming files or changing Git branches.
**The Cause:** Stale artifacts. 
**The Fix:** Always pass `clean` to the `xcodebuild` command in CI:
```bash
xcodebuild clean archive -project ...
```

## 6. Strict Concurrency & Actor Isolation Errors (Swift 6)
**The Error:** The build fails with `exit code 65`. If you remove `xcpretty` from the `xcodebuild` pipeline to see raw logs, you'll see errors like: `Call to main actor-isolated method 'log' in a synchronous nonisolated context`.
**The Cause:** With Swift 6 (or Swift 5.10 strict concurrency enabled), the compiler aggressively enforces thread safety. If a UI-bound class (like `DebugLogger` which is an `ObservableObject` and thus often implicitly `@MainActor`) is called directly from a background `actor` (like `ExarotonClient`), the compiler will reject it. Older legacy patterns like `if Thread.isMainThread` inside the logger are no longer accepted as valid isolation guarantees by the compiler.
**The Fix:**
- Remove internal `Thread.isMainThread` checks from the logger or singleton.
- At the **call site** (inside the background actor or `Task`), explicitly wrap the call to the MainActor-isolated method using `Task { @MainActor in ... }`:
```swift
// Incorrect (causes exit code 65):
DebugLogger.shared.log("Network request")

// Correct (satisfies strict concurrency):
Task { @MainActor in 
    DebugLogger.shared.log("Network request") 
}
```

## How to Debug
If a workflow fails, download the raw log file from the GitHub Actions dashboard and search for `error:` (with the colon). `xcodebuild` output is notoriously verbose, so searching for `error:` or `** ARCHIVE FAILED **` will help you quickly locate the actual compiler failure. If the output is being piped to `xcpretty`, remove `| xcpretty` temporarily from your `.yml` to see the full compiler diagnostics.
