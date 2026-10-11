$ErrorActionPreference = 'Stop'
Write-Host '=== PennyPal verification ===' -ForegroundColor Cyan
flutter --version
flutter clean
flutter pub get
flutter analyze
flutter test
Write-Host '=== Web build ===' -ForegroundColor Cyan
flutter build web
Write-Host '=== Android debug build ===' -ForegroundColor Cyan
flutter build apk --debug
Write-Host '=== Verification complete ===' -ForegroundColor Green
