# iOS host / WidgetKit setup

The source uses the X10 Think application group `group.com.x10think.onefourthree` and the private `143://` URL scheme. A real HTTPS Universal Link domain is intentionally not fabricated in this package.

Before App Store release on a Mac:

1. Set the Runner bundle identifier to `com.x10think.onefourthree` (or the final App Store identifier if a different one is registered).
2. Place `GoogleService-Info.plist` in `ios/Runner/` and enable Firebase/APNs capabilities. No secret/config file is committed here.
3. Add `Runner.entitlements` to the Runner target and ensure the App Group is registered in the Apple Developer account.
4. Create/attach a Widget Extension target using `OneFourThreeWidgets.swift` and the same App Group.
5. Enable Push Notifications and Background Modes only when configured.
6. If Universal Links are required, add the real Associated Domain and publish the matching `apple-app-site-association` file.
7. Test camera, microphone, Photos, location, Face ID, deep links and widget privacy on physical iOS devices.
