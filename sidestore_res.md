# SideStore Remote Download Functionality

SideStore (and AltStore) allows users to add custom "Sources" to download and automatically update third-party apps directly on their devices. A Source is simply a JSON file hosted on the web that conforms to the SideStore/AltStore source schema.

## How SideStore Sources Work

1. **JSON Schema:** A source file contains metadata about the repository, news articles, and a list of `apps`. Each app entry contains metadata (name, developer, bundle identifier) and an array of `versions`.
2. **Versions:** Each version specifies the version number, date, changelog, and the direct `downloadURL` to the compiled `.ipa` file.
3. **Deep Linking:** Users add the source to SideStore by tapping a link in the format `sidestore://source?url=<URL_TO_JSON>`.

## Implementing SideStore Downloads for ExarotonApp

Since this project already builds an IPA via GitHub Actions (as seen in `README.md`), we can automate the creation of a SideStore-compatible JSON source that points to our GitHub Releases.

### Step 1: Create a Base JSON Template
Create a `sidestore.json` file in the root of the repository. This will serve as the base template.

```json
{
  "name": "ExarotonApp Source",
  "identifier": "com.exarotonapp.source",
  "subtitle": "Official source for the Exaroton iOS App",
  "apps": [
    {
      "name": "ExarotonApp",
      "bundleIdentifier": "com.abhijot.exarotonapp",
      "developerName": "Abhijot",
      "subtitle": "Manage Exaroton servers.",
      "localizedDescription": "A full-featured native iOS app for managing Exaroton Minecraft servers.",
      "iconURL": "https://raw.githubusercontent.com/AbhijotSingh2B/exaroton-ios/main/icon.png",
      "tintColor": "#007AFF",
      "permissions": {
        "background-audio": "Used to keep websockets alive (if applicable)"
      },
      "versions": []
    }
  ]
}
```

### Step 2: Automate with GitHub Actions
Currently, the `build-ipa.yml` creates an IPA and uploads it as an artifact. We need to modify this (or create a new release workflow) so that when a GitHub Release is created:
1. The IPA is attached to the GitHub Release.
2. A script dynamically updates the `sidestore.json` by prepending a new entry to the `versions` array.

Example script logic in the Action:
```bash
VERSION="1.0.0"
DATE=$(date -Iseconds)
DOWNLOAD_URL="https://github.com/AbhijotSingh2B/exaroton-ios/releases/download/$VERSION/ExarotonApp.ipa"
SIZE=$(stat -c%s ExarotonApp.ipa)

# Use jq to inject the new version into the JSON
jq --arg v "$VERSION" --arg d "$DATE" --arg url "$DOWNLOAD_URL" --arg size "$SIZE" \
'.apps[0].versions = [{"version": $v, "date": $d, "downloadURL": $url, "size": $size, "localizedDescription": "New release"}] + .apps[0].versions' \
sidestore.json > sidestore_updated.json
```

### Step 3: Hosting the Source
Once the JSON is updated, the Action should push the `sidestore.json` back to a `gh-pages` branch or the `main` branch. 
The raw URL of this JSON file (e.g., `https://raw.githubusercontent.com/AbhijotSingh2B/exaroton-ios/main/sidestore.json`) becomes the source URL.

Alternatively, you can use **SideSource**, a Cloudflare Worker framework specifically designed to parse GitHub Releases and dynamically generate the JSON on the fly without needing a GitHub Action to edit the JSON file. This prevents GitHub API rate limits and simplifies the repo setup.

### Step 4: Add the Install Button to README
Update the `README.md` to include a deep link button so users can install it with one tap:

```markdown
[Add to SideStore](sidestore://source?url=https://raw.githubusercontent.com/AbhijotSingh2B/exaroton-ios/main/sidestore.json)
```

## Common Errors & Troubleshooting

When dealing with SideStore/AltStore JSON sources, you might encounter installation or refresh errors. Here are the most common pitfalls:

1. **Missing Top-Level `downloadURL` (SideStore Specific):**
   - **Error:** The source fails to add or throws a "CoreData" error.
   - **Cause:** SideStore strictly requires a `downloadURL` key at the top level of the app entry, even if you define individual `downloadURL`s inside the `versions` array. 
   - **Fix:** Ensure the base app object has a fallback `downloadURL`.

2. **Bundle Identifier Mismatch:**
   - **Error:** App fails to install or update.
   - **Cause:** The `bundleIdentifier` in your `sidestore.json` does not perfectly match the `CFBundleIdentifier` compiled into the `.ipa` file.
   - **Fix:** Verify your Xcode project bundle ID matches the JSON file exactly.

3. **Serving HTML Instead of JSON:**
   - **Error:** SideStore says the source is invalid or unreadable.
   - **Cause:** You provided a link to the GitHub blob page (e.g., `github.com/.../sidestore.json`) instead of the raw file content.
   - **Fix:** Always use the `raw.githubusercontent.com/...` URL.

4. **Malformed JSON Syntax:**
   - **Error:** Parsing fails entirely.
   - **Cause:** Automated `jq` scripts sometimes leave trailing commas, or strings are not escaped properly (e.g., in the changelog).
   - **Fix:** Run the generated output through a JSON validator before publishing, and ensure double quotes are escaped (`\"`).

5. **GitHub Raw Caching:**
   - **Error:** You pushed an update, but SideStore isn't seeing the new version.
   - **Cause:** `raw.githubusercontent.com` URLs are cached by Fastly for ~5 minutes. 
   - **Fix:** Wait 5 minutes for the cache to clear, or append a dummy query parameter to bypass cache during testing (e.g., `?v=1`).

## AI Implementation Instructions

If you want an AI coding assistant to implement this functionality for you automatically, you can copy and paste the following prompt to them:

> **Prompt for AI Assistant:**
> "Please implement SideStore remote download and update functionality for this repository. Follow these steps:
> 1. Create a `sidestore.json` file in the root directory following the standard SideStore/AltStore source schema. Set the app name to 'ExarotonApp' and the bundle identifier to 'com.abhijot.exarotonapp'.
> 2. Modify the `.github/workflows/build-ipa.yml` (or create a new release workflow) so that when a GitHub Release is published, it builds the unsigned IPA and attaches it directly to the GitHub Release.
> 3. Add a step in the same GitHub Action to automatically update the `sidestore.json` file. It should prepend the new release version, date, file size, and the direct `.ipa` download URL to the `versions` array.
> 4. Have the workflow commit and push the updated `sidestore.json` back to the repository.
> 5. Update the `README.md` file to include a SideStore install link: `sidestore://source?url=https://raw.githubusercontent.com/AbhijotSingh2B/exaroton-ios/main/sidestore.json`."
