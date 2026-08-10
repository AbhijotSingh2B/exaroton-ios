# GitHub Release Best Practices

When publishing a new release to a GitHub repository, following standard best practices ensures that your users, contributors, and automated systems can easily understand and consume your updates.

## 1. Use Semantic Versioning (SemVer)
Always tag your releases with standard semantic versioning (e.g., `v1.2.3`).
- **Major (1.x.x):** Breaking changes or massive overhauls.
- **Minor (x.2.x):** New features that are backwards compatible.
- **Patch (x.x.3):** Bug fixes and minor tweaks.
Using the `v` prefix is a standard GitHub convention and helps automated tools recognize version tags.

## 2. Automate Builds with GitHub Actions
Instead of manually compiling and uploading binaries (like `.ipa`, `.apk`, or `.exe` files), use CI/CD pipelines.
- Configure a GitHub Action that triggers on `release` creation or when a new `tag` is pushed.
- Have the Action build the project cleanly and attach the compiled artifacts directly to the release. This ensures the binary exactly matches the source code at that tag.

## 3. Write Clear and Structured Release Notes
Your release notes should act as a changelog. A good structure includes:
- **🚀 New Features:** What was added.
- **🐛 Bug Fixes:** What was fixed.
- **⚠️ Breaking Changes:** Anything that requires the user to change their workflow or configuration.
- **🔨 Under the Hood:** Tech debt resolution, refactoring, or dependency updates.
*Tip: You can use GitHub's "Generate release notes" button to automatically compile PR titles since the last release.*

## 4. Use Pre-Releases for Testing
If you are pushing a major update (e.g., v2.0.0), publish it as a **Pre-release** (Alpha/Beta) first. This signals to your users that the build might contain bugs and is intended for early adopters and testers.

## 5. Branching Strategy
Never push a release from a messy working branch. 
- Releases should be tagged and cut from your primary stable branch (e.g., `main` or `master`).
- Alternatively, use a dedicated `release` branch if you need to finalize versions before merging them back into the main branch.

## 6. Include Hashes / Checksums (Security)
For users downloading compiled binaries, it is good practice to include a `SHA256` checksum in the release notes. This allows users to verify that the file wasn't corrupted during download or tampered with.

## 7. Keep the Git Tag and GitHub Release in Sync
A GitHub Release is intrinsically tied to a Git Tag. 
- The standard CLI workflow is to push the tag first: `git tag v1.0.0 && git push origin v1.0.0`.
- Then, go to the GitHub UI to draft the release from that existing tag, rather than creating the tag dynamically through the UI, to ensure local and remote histories match perfectly.
