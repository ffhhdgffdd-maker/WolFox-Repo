# WolFox Repo manifest (Android-only)

The client reads `app-repo.json` from the repository main branch.

Required app fields:
- `platform` (`android`)
- `name`
- `bundleIdentifier` (Android application ID)
- `versions`

Each version must include:
- `version`
- `downloadURL`
- The URL must point to an authorized HTTPS APK asset.

The application list, detail screen and Download APK button are generated from these values. iOS/IPA entries are rejected by the panel and filtered by the client.
