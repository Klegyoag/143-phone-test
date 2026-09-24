$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot
$ApiBaseUrl = "https://143-backend-staging.vercel.app/api/index.php/api/v1"
$OutputApk = Join-Path $ProjectRoot "143_M31_PHONE_TEST_DEBUG.apk"

Write-Host "=== 143 M31 Phone Test APK Builder ===" -ForegroundColor Cyan

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter is not installed or is not in PATH. Install Flutter stable and Android Studio/Android SDK, then re-run this script."
}

Write-Host "[1/7] Flutter environment" -ForegroundColor Yellow
flutter --version
flutter doctor -v
if ($LASTEXITCODE -ne 0) {
    Write-Warning "flutter doctor reported setup issues. Android toolchain errors must be fixed before APK compilation can succeed."
}

# The submitted source intentionally did not contain the Gradle wrapper binaries.
# Generate a clean temporary Flutter Android project and copy ONLY the wrapper files.
if (-not (Test-Path (Join-Path $ProjectRoot "android\gradlew.bat"))) {
    Write-Host "[2/7] Restoring missing Gradle wrapper without overwriting custom Android files" -ForegroundColor Yellow
    $TempProject = Join-Path $env:TEMP ("one_four_three_wrapper_" + [guid]::NewGuid().ToString("N"))
    flutter create --platforms=android --org com.x10think --project-name one_four_three $TempProject
    if ($LASTEXITCODE -ne 0) { throw "Failed to generate temporary Flutter Android scaffold." }

    Copy-Item (Join-Path $TempProject "android\gradlew") (Join-Path $ProjectRoot "android\gradlew") -Force
    Copy-Item (Join-Path $TempProject "android\gradlew.bat") (Join-Path $ProjectRoot "android\gradlew.bat") -Force
    New-Item -ItemType Directory -Force -Path (Join-Path $ProjectRoot "android\gradle\wrapper") | Out-Null
    Copy-Item (Join-Path $TempProject "android\gradle\wrapper\*") (Join-Path $ProjectRoot "android\gradle\wrapper") -Force
    Remove-Item $TempProject -Recurse -Force
} else {
    Write-Host "[2/7] Gradle wrapper already present" -ForegroundColor Green
}

Write-Host "[3/7] Fetching Dart/Flutter dependencies" -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed." }

Write-Host "[4/7] Static analysis" -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) { throw "flutter analyze failed. APK build stopped so you do not install a knowingly broken build." }

Write-Host "[5/7] Flutter tests" -ForegroundColor Yellow
flutter test
if ($LASTEXITCODE -ne 0) { throw "flutter test failed. APK build stopped." }

Write-Host "[6/7] Building debug APK for physical-phone testing" -ForegroundColor Yellow
flutter build apk --debug --dart-define="API_BASE_URL=$ApiBaseUrl"
if ($LASTEXITCODE -ne 0) { throw "flutter build apk failed." }

$BuiltApk = Join-Path $ProjectRoot "build\app\outputs\flutter-apk\app-debug.apk"
if (-not (Test-Path $BuiltApk)) { throw "Flutter reported success but app-debug.apk was not found." }
Copy-Item $BuiltApk $OutputApk -Force

Write-Host "[7/7] APK ready" -ForegroundColor Green
$hash = Get-FileHash $OutputApk -Algorithm SHA256
Write-Host "APK: $OutputApk" -ForegroundColor Green
Write-Host "SHA-256: $($hash.Hash)" -ForegroundColor Green
Write-Host "API: $ApiBaseUrl" -ForegroundColor Green
Write-Host "Copy 143_M31_PHONE_TEST_DEBUG.apk to your Android phone and install it." -ForegroundColor Cyan
