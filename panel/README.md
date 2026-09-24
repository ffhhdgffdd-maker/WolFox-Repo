# WolFox Repo Panel Integration

The panel publishes application metadata to the canonical `app-repo.json` manifest.

Required application fields:
- name
- bundleIdentifier
- version
- downloadURL

Optional:
- developerName
- subtitle
- localizedDescription
- iconURL
- category
- size
- minOSVersion

Hidden applications must be excluded from the public `apps` array while remaining available in the panel's own storage.
