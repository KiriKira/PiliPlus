# PiliPlus custom build signing

The custom foldable PiliPlus APKs must always be signed by the same key so that
future builds can be installed as in-place upgrades.

Current signing certificate (generated 2026-10-19):

`6C:E8:0D:24:4E:5B:E2:75:36:9B:46:DF:A6:04:05:A8:91:72:58:F8:FD:91:64:5F:44:FE:31:B1:BD:32:90:04`

Subject `CN=PiliPlus Custom Build, O=KiriKira, C=JP`, RSA 4096,
valid until 2126-09-25.

## Long-term storage

Match Kirigram's signing model: store the keystore and credentials as GitHub
Repository Secrets, not as an Actions cache.

Required secrets:

- `PILIPLUS_KEYSTORE_BASE64`
- `PILIPLUS_KEYSTORE_PASSWORD`
- `PILIPLUS_KEY_ALIAS`
- `PILIPLUS_KEY_PASSWORD`

The build workflow decodes the keystore for the current runner only, validates
its certificate fingerprint against the pinned value above, configures Gradle
to use it, and then validates the certificate again from every final APK before
uploading or publishing anything.

A missing, partial, or mismatched secret configuration fails the workflow.
The workflow never generates or accepts a replacement signing key.

## Key history

- 2026-09-21 — first custom build key (`B8:19:28:…`, alias `androiddebugkey`).
  It only ever lived in the legacy Actions cache `piliplus-kirikira-signing-v1`.
  That cache entry expired while unused, and the 2026-09-28 encrypted export
  artifact expired before it was retrieved, so the private key was not
  recoverable.
- 2026-10-19 — rotated to the current `6C:E8:0D:…` key (alias `piliplus`),
  stored in the four repository secrets above. The obsolete
  `export-signing-keystore.yml` migration workflow was removed at the same time.

Rotation consequence: APKs signed with `B8:19:28:…` (every custom build up to
and including 2026-09) cannot be updated in place by `6C:E8:0D:…` builds.
Uninstall the old app once before installing the first build of the new key.

## Backup

Keep an offline copy of the current keystore together with its store password,
key alias and key password. Losing the private key again forces another
one-time uninstall on every device that runs these builds.
