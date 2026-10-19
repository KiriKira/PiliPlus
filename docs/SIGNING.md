# PiliPlus custom build signing

The custom foldable PiliPlus APKs must always be signed by the same key so that
future builds can be installed as in-place upgrades.

Public certificate SHA-256 fingerprint:

`B8:19:28:5C:5A:86:29:83:2A:A2:90:E2:47:62:2F:94:99:18:BA:6F:28:CC:D4:F8:BE:14:EC:28:ED:7A:3E:57`

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

## One-time migration from the legacy Actions cache

The current B8:19:... key predates the Repository Secrets setup and is still
available in the legacy Actions cache. The normal build workflow no longer uses
that cache at all. It intentionally fails until the Repository Secrets above
are configured.

Use the manual `Export PiliPlus signing keystore` workflow once to export the
legacy cached key encrypted to an age recipient that you control.

On a trusted local machine:

```bash
age-keygen -o piliplus-age-key.txt
```

Copy the printed public recipient (the `age1...` value), run the export
workflow, and paste that recipient into its input. Download the resulting
`piliplus-signing-keystore-encrypted` artifact, then decrypt it locally:

```bash
age -d -i piliplus-age-key.txt \
  -o piliplus-release.keystore \
  piliplus-release.keystore.age
```

Verify the certificate before storing it:

```bash
keytool -list -v \
  -keystore piliplus-release.keystore \
  -storepass android \
  -alias androiddebugkey
```

For the currently pinned key, the legacy keystore uses:

- store password: `android`
- key alias: `androiddebugkey`
- key password: `android`

Then configure the four Repository Secrets. With GitHub CLI:

```bash
gh secret set PILIPLUS_KEYSTORE_BASE64 \
  -b "$(base64 -w0 piliplus-release.keystore)"
gh secret set PILIPLUS_KEYSTORE_PASSWORD -b 'android'
gh secret set PILIPLUS_KEY_ALIAS -b 'androiddebugkey'
gh secret set PILIPLUS_KEY_PASSWORD -b 'android'
```

Keep an offline backup of the original keystore. Losing the private key means
new builds can no longer update an installed copy signed by this certificate.

After the four Repository Secrets are configured, the normal build workflow
has no signing-key cache fallback and cannot generate a replacement key. The
manual export workflow is only a migration aid and can be deleted after you
have verified a successful secret-backed build and stored an offline backup.
