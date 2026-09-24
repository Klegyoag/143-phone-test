# Android host setup

Application ID / namespace: `com.x10think.onefourthree`.

## Release signing

Production builds never use the debug signing key. Copy `key.properties.example` to `key.properties`, point it at the private upload keystore, and keep both files/secrets out of source control. Without `key.properties`, a release build remains unsigned rather than silently using the debug key.

## Firebase / push

Place the real `google-services.json` at `android/app/google-services.json`, then enable the Google Services Gradle plugin in `android/app/build.gradle.kts`. No Firebase credential file is committed here.

## Deep links

The app currently supports the private `143://` scheme. HTTPS App Links are intentionally not declared until a real production domain and signing certificate are available. When a domain is ready, add the verified HTTPS intent filter and publish `/.well-known/assetlinks.json`.

## Networking

Production networking disables cleartext HTTP. For local Laravel development use a debug-only network security override or an HTTPS dev tunnel; do not weaken the release manifest.
