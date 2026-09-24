143 M31 — FINAL CLOUD PHONE BUILD
==================================

This package contains a GitHub Actions workflow:
.github/workflows/build-phone-apk.yml

The workflow performs the complete phone-test build gate:
1. Java 17 setup
2. Flutter stable setup
3. Gradle wrapper restoration if missing
4. flutter pub get
5. flutter analyze
6. flutter test
7. flutter build apk --debug --dart-define=API_BASE_URL=https://143-api.onrender.com/api/v1
8. APK rename to 143_M31_PHONE_TEST_DEBUG.apk
9. SHA-256 generation
10. APK artifact upload

The generated APK is a DEBUG build intended for direct Android phone testing, not Play Store publishing.

App identity: com.x10think.onefourthree
Version: 0.31.0+31
Minimum Android SDK: 23
Backend base URL: https://143-api.onrender.com/api/v1
