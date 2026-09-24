# Milestone 31 Validation

## Executable in this package environment

- Backend PHP static validator
- PHP syntax lint
- API/OpenAPI/Postman consistency
- Source-level import/reference scans
- Mobile identifier, cleartext-network and release signing configuration checks
- JSON parse checks

## Corrected M31 hardening checks

The corrected source validator additionally verifies bootstrap/contract-count consistency, auth-safe idempotency caching, refresh/session linkage and atomic rotation, logout refresh revocation, unified active-session responses, couple-membership cleanup on account deletion, bounded FCM HTTP retry, and actionable memory-share deep links.

## Requires a Flutter SDK machine

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter test integration_test
flutter run
```

## Requires real devices / credentials

- Android/iOS notification delivery
- two-device WebRTC + TURN interoperability
- Spotify account/provider behavior
- background location and OS permission lifecycle
- widgets / biometric behavior
- security-reviewed E2EE and encrypted backup/device migration

No such item is marked complete solely from static source inspection.
