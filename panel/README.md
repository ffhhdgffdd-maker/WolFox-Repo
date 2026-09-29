# WolFox Repo Panel Integration

The panel publishes **Android applications only** to the canonical `app-repo.json` manifest.

Required application fields:
- name
- applicationId
- version
- apkURL
- platform (`android`)

Optional:
- developerName
- subtitle
- localizedDescription
- iconURL
- category
- size
- minAndroidVersion

Hidden applications must be excluded from the public `apps` array while remaining available in the panel's own storage.
IPA, iOS, and certificate files must never be uploaded through this panel.
