# 143 Milestone 31 — Free Release Candidate

## Product access

143 is currently a **free-only app**. All active product features are available to every user.

## Active capability scope

The current active matrix contains **490 capabilities** after applying the current authentication and free-access scope.

- COMPLETE: **349**
- PARTIAL: **128**
- INTEGRATION_PENDING: **5**
- SECURITY_REVIEW_REQUIRED: **8**

Statuses remain conservative: source implementation is not promoted to device/provider/security certification without executable evidence.

## Milestone 31 source work

- The full current feature set is exposed to every user under the free-access model.
- Profile-photo editor now provides square crop, pinch zoom, drag/reposition and rotation before upload.
- Shared-album uploads can preserve an optional current-location geotag when location permission is already granted, and albums can sort by location metadata without a new API.
- Memory creation supports current-location attachments.
- File/media uploads expose progress and retry transient signed-upload failures.
- Android release networking blocks cleartext; the Flutter release client refuses a non-HTTPS API base URL.
- Android uses secure-window protection for sensitive screens; iOS adds privacy shielding for app-switcher/screen-capture states supported by public APIs.
- Existing device authentication is source-wired; physical biometric QA is still required.
- Memory attachments now preview image/video/audio and securely open documents/files through short-lived URLs.
- Chat previews include secure document opening in addition to image/video/audio/location.
- Game history now has a dedicated session list and result-detail view.
- Shared albums can select an existing private photo as the custom album cover.

## Corrected release hardening (2026-09-23)

The corrected source package also closes the following release defects found during adversarial review:

- Bootstrap API operation/path counts are derived from the authoritative contract instead of stale constants.
- PHPUnit contract expectations now match the current 349-operation / 261-path contract.
- Authentication/public requests are excluded from idempotency response caching; authenticated cached bodies are application-encrypted and duplicate in-flight mutations are serialized by an atomic cache lock.
- Refresh-token rotation is transactionally locked to prevent double rotation.
- Access and refresh tokens are linked as one revocable session; logout revokes both and the Active Sessions API now returns one unified list.
- Account deletion removes the deleted user's couple membership.
- FCM OAuth/send operations have bounded transient HTTP retries without duplicating successful device sends through whole-job retries.
- Memory sharing now produces an actionable private in-app deep link rather than an unused random token.

## Remaining integration-dependent items

1. Synchronized Spotify listening — real Spotify credentials/accounts and two-device provider QA.
2. General push notifications — real FCM/APNs credentials and physical-device delivery QA.
3. Time Capsule reveal notifications — end-to-end provider delivery/background QA.
4. Incoming-call notifications — provider delivery and background/terminated call presentation QA.
5. Lock-screen widget support — signed native extension/device certification where the OS supports it.

## Security-review-required items

The following are deliberately **not** marked complete by inventing custom cryptography or claiming an unreviewed security guarantee:

- on-device face grouping privacy review,
- E2EE for private text,
- E2EE for private media,
- E2EE guarantees for voice/video,
- encrypted cloud backup,
- encrypted backup restore,
- encrypted new-phone transfer,
- recovery-key lifecycle.

## What still cannot be certified from this ZIP alone

- Flutter analyzer/widget/integration tests because Flutter/Dart SDK is not present in this execution environment.
- Real FCM/APNs delivery and background/terminated notification behavior.
- Two-device WebRTC/TURN interoperability and audio-route behavior.
- Spotify account/provider behavior.
- Physical photo-editor, biometric, location and OS-widget QA.
- Independent security review for the security items above.
- Full Laravel runtime/PHPUnit/deployment tests with Composer dependencies and real infrastructure.

Those items remain explicitly marked rather than being falsely reported as complete.
