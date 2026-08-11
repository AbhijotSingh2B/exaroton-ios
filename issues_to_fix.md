# Issues to Fix

This document tracks known issues, technical debt, and required fixes across the Exaroton app codebase.

## High Priority

### 1. GitHub Actions CI Violates AGENTS.md Rules
- **Semantic Versioning:** The `.github/workflows/build-ipa.yml` and `update-sidestore.yml` currently use static "rolling release" tags (`stable` and `nightly`) instead of triggering off Semantic Version tags (e.g., `v1.0.1`).
- **Main Branch Restrictions:** The workflows incorrectly trigger on pushes directly to the `main` branch, violating the `AGENTS.md` rule that code should only be pushed to `development`.
- **Missing Checksum:** The `build-ipa.yml` does not generate the required `sha256` checksum for the `.ipa` file before releasing it.
- **SideStore Updates Broken:** Because versions aren't incrementing properly, `update-sidestore.yml` hardcodes version `1.0.0`. Users on SideStore will not receive over-the-air updates unless the version number dynamically increments.
- **Xcode Flags:** `build-ipa.yml` is missing `CODE_SIGN_ENTITLEMENTS=""` as recommended by `ai_docs/github_actions_xcode_errors.md`.

## Medium Priority
*(Empty)*

## Low Priority
*(Empty)*
