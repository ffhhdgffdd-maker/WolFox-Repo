# WolFox Repo manifest

The client reads `app-repo.json` from the repository main branch.

Required app fields:
- `name`
- `bundleIdentifier`
- `versions`

Each version must include:
- `version`
- `downloadURL`

The application list, detail screen and Download button are generated from these values. The download URL should point to the corresponding authorized GitHub Release asset.
