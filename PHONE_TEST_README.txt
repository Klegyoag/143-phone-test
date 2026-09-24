143 M31 — ANDROID PHONE TEST BUILD
==================================

Goal
----
Build a DEBUG APK for direct installation on a physical Android phone.
The build command points the app to:
https://143-api.onrender.com/api/v1

Why debug APK?
--------------
It is ideal for first-device QA and does not require your production signing keystore.
Do NOT publish this debug APK to an app store.

Requirements on Windows
-----------------------
1. Flutter stable SDK installed and in PATH.
2. Android Studio installed with Android SDK + command-line/build tools.
3. Run `flutter doctor -v` and resolve Android toolchain errors.
4. Internet access for `flutter pub get` and Gradle dependencies.

Build
-----
Double-click:
BUILD_PHONE_APK.bat

The script will:
- verify Flutter/Android setup;
- generate ONLY the missing Gradle wrapper files in a temporary project;
- preserve the custom AndroidManifest, FLAG_SECURE/privacy configuration, widget code, and project Gradle config;
- run flutter pub get;
- run flutter analyze;
- run flutter test;
- build the debug APK with API_BASE_URL=https://143-api.onrender.com/api/v1;
- copy the final APK to this folder as:
  143_M31_PHONE_TEST_DEBUG.apk

Install on phone
----------------
1. Copy 143_M31_PHONE_TEST_DEBUG.apk to the phone.
2. Tap it.
3. Android may ask you to allow "Install unknown apps" for your browser/file manager.
4. Install and open 143.

Important first-test limitations
--------------------------------
- Firebase/FCM push notifications need the real android/app/google-services.json and enabled Google Services Gradle plugin. Basic app testing can proceed without claiming push readiness.
- Spotify requires its provider/client configuration.
- WebRTC/TURN needs a second physical device for proper interoperability testing.
- The configured backend URL must actually be deployed and reachable. If it is not live, UI may open but login/network features will fail.

If the script fails
-------------------
Copy the full terminal output into ChatGPT. The first failing error is usually enough to diagnose the build.
