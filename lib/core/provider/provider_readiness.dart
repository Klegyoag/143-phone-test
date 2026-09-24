class ProviderReadinessItem {
  const ProviderReadinessItem({required this.name, required this.ready, required this.detail, this.secretRequired = false});
  final String name;
  final bool ready;
  final String detail;
  final bool secretRequired;
}

/// Non-secret readiness inspection. This never reads or displays provider
/// secrets. It only reports whether public build-time identifiers/configuration
/// hooks are present so QA can distinguish code readiness from credential setup.
class ProviderReadiness {
  const ProviderReadiness();

  List<ProviderReadinessItem> inspect() {
    const reverbKey = String.fromEnvironment('REVERB_APP_KEY');
    const spotifyClientId = String.fromEnvironment('SPOTIFY_CLIENT_ID');
    const updateManifest = String.fromEnvironment('APP_UPDATE_MANIFEST_URL');
    return [
      ProviderReadinessItem(
        name: 'Laravel Reverb',
        ready: reverbKey.isNotEmpty,
        detail: reverbKey.isNotEmpty ? 'Public Reverb app key is configured.' : 'Set REVERB_APP_KEY at build time; no websocket secret belongs in Flutter.',
      ),
      const ProviderReadinessItem(
        name: 'Firebase / FCM / APNs',
        ready: false,
        secretRequired: true,
        detail: 'Runtime readiness requires platform files/capabilities: android/app/google-services.json and ios/Runner/GoogleService-Info.plist. These are intentionally not committed.',
      ),
      ProviderReadinessItem(
        name: 'Spotify',
        ready: spotifyClientId.isNotEmpty,
        detail: spotifyClientId.isNotEmpty ? 'Public Spotify client id is configured; native/provider QA is still required.' : 'Set SPOTIFY_CLIENT_ID and provider redirect configuration. Never embed a Spotify client secret.',
      ),
      const ProviderReadinessItem(
        name: 'YouTube',
        ready: true,
        detail: 'Embedded YouTube player boundary exists. Provider policy/network/device QA is still required.',
      ),
      ProviderReadinessItem(
        name: 'App update manifest',
        ready: updateManifest.startsWith('https://'),
        detail: updateManifest.startsWith('https://')
            ? 'HTTPS release manifest is configured for automatic version compatibility checks.'
            : 'Set APP_UPDATE_MANIFEST_URL to a public HTTPS JSON manifest. No store secret belongs in Flutter.',
      ),
      const ProviderReadinessItem(
        name: 'WebRTC peer signaling',
        ready: true,
        detail: 'Current Laravel handoff includes authenticated offer/answer/ICE publish endpoints and private realtime events. Physical two-device interoperability still requires QA.',
      ),
      const ProviderReadinessItem(
        name: 'E2EE',
        ready: false,
        secretRequired: true,
        detail: 'SECURITY REVIEW REQUIRED: integrate a reviewed protocol/library and secure on-device private-key lifecycle. Custom cryptography is prohibited.',
      ),
    ];
  }
}
