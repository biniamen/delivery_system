# Creavers Delivery System — Command Reference

Run commands from PowerShell unless a section explicitly says macOS. The repository root is:

```text
C:\Users\HP\Documents\ChatGPT\Delivery System
```

## 1. Open the project

```powershell
Set-Location "C:\Users\HP\Documents\ChatGPT\Delivery System"
code .
```

Open the Flutter application in Android Studio:

```powershell
& "C:\Program Files\Android\Android Studio\bin\studio64.exe" "C:\Users\HP\Documents\ChatGPT\Delivery System\mobile"
```

## 2. Required Windows environment

The following user environment variables are already configured on the development computer. Reopen PowerShell and Android Studio after changing them.

```powershell
[Environment]::SetEnvironmentVariable("ANDROID_HOME", "C:\Users\HP\AppData\Local\Android\Sdk", "User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", "C:\Users\HP\AppData\Local\Android\Sdk", "User")
[Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Android\Android Studio\jbr", "User")
```

Configure the current PowerShell session:

```powershell
$env:ANDROID_HOME = "C:\Users\HP\AppData\Local\Android\Sdk"
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:Path = "C:\Users\HP\flutter\bin;$env:ANDROID_HOME\platform-tools;$env:ANDROID_HOME\emulator;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:JAVA_HOME\bin;$env:Path"
```

Verify the toolchain:

```powershell
flutter --no-version-check --version
flutter --no-version-check doctor -v
adb version
```

The newest Android CLI may make Flutter Doctor report an unknown Android license status even after licenses are accepted. A successful Android build is the practical verification.

## 3. Start, stop, and restart the complete local system

```powershell
Set-Location "C:\Users\HP\Documents\ChatGPT\Delivery System"
.\scripts\start-local.ps1
.\scripts\stop-local.ps1
.\scripts\restart-local.ps1
```

Skip rebuilding the Flutter web preview when only the API or native mobile app is needed:

```powershell
.\scripts\start-local.ps1 -SkipMobileBuild
```

Local addresses:

```text
Backend health:     http://localhost:5080/health/live
Dispatcher portal: http://localhost:4200
Mobile web preview: http://localhost:8080
```

Check listening ports:

```powershell
Get-NetTCPConnection -State Listen | Where-Object LocalPort -in 5080,4200,8080,55432
```

## 4. Backend only

Normal local development uses PostgreSQL on port `55432` through `start-local.ps1`. To run the API manually, configure development-only values in the current terminal:

```powershell
$env:ASPNETCORE_ENVIRONMENT = "Development"
$env:ConnectionStrings__Postgres = "Host=127.0.0.1;Port=55432;Database=creavers_delivery;Username=creavers_app;Password=creavers_dev"
$env:Jwt__SigningKey = "Creavers-Development-Signing-Key-2026-Must-Be-Long"
$env:DemoAccounts__CustomerPassword = "CreaversDemo!2026"
$env:DemoAccounts__DispatcherPassword = "CreaversDemo!2026"
$env:DemoAccounts__DriverPassword = "CreaversDemo!2026"
$env:DemoAccounts__StoreAdminPassword = "CreaversDemo!2026"
dotnet run --project .\backend\src\Creavers.Delivery.Api --urls http://0.0.0.0:5080
```

Health check:

```powershell
Invoke-RestMethod http://127.0.0.1:5080/health/live
```

## 5. Dispatcher portal only

```powershell
Set-Location "C:\Users\HP\Documents\ChatGPT\Delivery System\frontend\dispatcher-portal"
corepack enable
corepack prepare pnpm@11.19.0 --activate
pnpm install
pnpm start
```

Production build:

```powershell
pnpm build:production
```

## 6. Flutter dependencies and checks

```powershell
Set-Location "C:\Users\HP\Documents\ChatGPT\Delivery System\mobile"
flutter --no-version-check clean
flutter --no-version-check pub get
flutter --no-version-check analyze
flutter --no-version-check test
```

## 7. Android emulator

List and start the installed Pixel 8:

```powershell
emulator -list-avds
emulator -avd Pixel_8
adb devices -l
```

Run the app against the backend running on the same computer:

```powershell
Set-Location "C:\Users\HP\Documents\ChatGPT\Delivery System\mobile"
flutter --no-version-check run -d emulator-5554 `
  --dart-define=API_ORIGIN=http://10.0.2.2:5080 `
  --dart-define=GOOGLE_MAPS_ENABLED=false
```

`10.0.2.2` is valid only inside the Android emulator.

## 8. Physical Android phone over the same Wi-Fi

The phone and computer must be connected to the same Wi-Fi network. Find the computer's current address:

```powershell
ipconfig
```

Or capture the address automatically:

```powershell
$computerIp = (Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq "Up" -and $_.IPv4DefaultGateway } | Select-Object -First 1).IPv4Address.IPAddress
$computerIp
```

Make sure the API listens on all interfaces:

```powershell
dotnet run --project .\backend\src\Creavers.Delivery.Api --urls http://0.0.0.0:5080
```

On a trusted home/office network, run PowerShell as Administrator and configure a Private-network-only firewall rule:

```powershell
Set-NetConnectionProfile -InterfaceAlias "Wi-Fi 2" -NetworkCategory Private
New-NetFirewallRule `
  -DisplayName "Creavers Backend API (TCP 5080)" `
  -Direction Inbound `
  -Action Allow `
  -Protocol TCP `
  -LocalPort 5080 `
  -RemoteAddress LocalSubnet `
  -Profile Private
```

Verify the phone-facing health address from the computer. Replace the example address whenever DHCP changes it:

```powershell
Invoke-RestMethod http://192.168.1.6:5080/health/live
```

Run directly on a USB-connected phone using the computer's current Wi-Fi address:

```powershell
$computerIp = (Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq "Up" -and $_.IPv4DefaultGateway } | Select-Object -First 1).IPv4Address.IPAddress
flutter --no-version-check devices
flutter --no-version-check run -d <phone-device-id> `
  --dart-define=API_ORIGIN="http://${computerIp}:5080" `
  --dart-define=GOOGLE_MAPS_ENABLED=false
```

Build the small ARM64 phone-testing APK:

```powershell
$computerIp = (Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq "Up" -and $_.IPv4DefaultGateway } | Select-Object -First 1).IPv4Address.IPAddress
flutter --no-version-check build apk --release `
  --split-per-abi `
  --target-platform android-arm64 `
  --dart-define=API_ORIGIN="http://${computerIp}:5080" `
  --dart-define=GOOGLE_MAPS_ENABLED=false
```

Output:

```text
mobile\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

## 9. Physical Android phone over USB without a firewall rule

Enable Developer options and USB debugging on the phone, connect it, and approve the computer:

```powershell
adb devices -l
adb reverse tcp:5080 tcp:5080
```

Run or build using loopback:

```powershell
flutter --no-version-check run -d <phone-device-id> `
  --dart-define=API_ORIGIN=http://127.0.0.1:5080 `
  --dart-define=GOOGLE_MAPS_ENABLED=false
```

`adb reverse` must be repeated after reconnecting or restarting the phone.

## 10. Android packages

Small ARM64 testing APK for most modern phones:

```powershell
flutter --no-version-check build apk --release `
  --split-per-abi `
  --target-platform android-arm64 `
  --dart-define=API_ORIGIN=https://api.example.com `
  --dart-define=GOOGLE_MAPS_ENABLED=true `
  --dart-define=GOOGLE_MAPS_MAP_ID=<map-id>
```

All supported APK architectures:

```powershell
flutter --no-version-check build apk --release --split-per-abi `
  --dart-define=API_ORIGIN=https://api.example.com `
  --dart-define=GOOGLE_MAPS_ENABLED=true `
  --dart-define=GOOGLE_MAPS_MAP_ID=<map-id>
```

Google Play App Bundle, which lets Play deliver optimized device-specific files:

```powershell
flutter --no-version-check build appbundle --release `
  --dart-define=API_ORIGIN=https://api.example.com `
  --dart-define=GOOGLE_MAPS_ENABLED=true `
  --dart-define=GOOGLE_MAPS_MAP_ID=<map-id>
```

Install an APK through USB:

```powershell
adb install -r ".\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
```

The current release configuration uses the development signing key. Configure a protected production keystore before Play Store distribution.

## 11. Google Maps development configuration

```powershell
Set-Location "C:\Users\HP\Documents\ChatGPT\Delivery System\mobile"
Copy-Item .\android\local.defaults.properties .\android\secrets.properties
```

Put the Android-restricted key in the ignored `android/secrets.properties` file, then run:

```powershell
flutter --no-version-check run `
  --dart-define=API_ORIGIN=http://10.0.2.2:5080 `
  --dart-define=GOOGLE_MAPS_ENABLED=true `
  --dart-define=GOOGLE_MAPS_MAP_ID=<map-id>
```

Never commit API keys or `secrets.properties`.

## 12. iOS — macOS only

```bash
cd mobile
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run \
  --dart-define=API_ORIGIN=http://127.0.0.1:5080 \
  --dart-define=GOOGLE_MAPS_ENABLED=false
```

Unsigned development build:

```bash
flutter build ios --debug --no-codesign \
  --dart-define=API_ORIGIN=http://127.0.0.1:5080 \
  --dart-define=GOOGLE_MAPS_ENABLED=false
```

## 13. Regenerate Android and iOS platform projects

Commit current platform configuration before regeneration:

```powershell
Set-Location "C:\Users\HP\Documents\ChatGPT\Delivery System\mobile"
flutter --no-version-check clean
flutter --no-version-check pub get
flutter --no-version-check create `
  --platforms=android,ios `
  --org com.creavers `
  --project-name creavers_delivery_mobile `
  .
```

Reapply map keys, permissions, signing, and other platform-specific configuration after regeneration if Flutter changes those files.

## 14. Connection and complete-flow checks

```powershell
Set-Location "C:\Users\HP\Documents\ChatGPT\Delivery System\mobile"
$env:CREAVERS_TEST_EMAIL = "customer@demo.creavers.local"
$env:CREAVERS_TEST_PASSWORD = "CreaversDemo!2026"
dart run .\tool\backend_connection_check.dart --origin=http://127.0.0.1:5080
dart run .\tool\full_order_flow_check.dart --origin=http://127.0.0.1:5080
```

Development accounts:

```text
customer@demo.creavers.local
dispatcher@demo.creavers.local
driver@demo.creavers.local
storeadmin@demo.creavers.local
Password: CreaversDemo!2026
Customer onboarding OTP: 246810
```

## 15. Automated verification

```powershell
Set-Location "C:\Users\HP\Documents\ChatGPT\Delivery System"
.\scripts\check-foundation.ps1
dotnet test .\backend\Creavers.Delivery.slnx

Set-Location .\frontend\dispatcher-portal
pnpm test
pnpm build:production

Set-Location ..\..\mobile
flutter --no-version-check analyze
flutter --no-version-check test
```

Complete CEO/client demonstration readiness check, including the real database-backed flow:

```powershell
Set-Location "C:\Users\HP\Documents\ChatGPT\Delivery System"
$env:CREAVERS_TEST_PASSWORD = "CreaversDemo!2026"
.\scripts\check-demo-readiness.ps1
```

## 16. Database migrations

```powershell
Set-Location "C:\Users\HP\Documents\ChatGPT\Delivery System\backend"
dotnet tool restore
dotnet ef migrations add DescribeTheChange `
  --project .\src\Creavers.Delivery.Infrastructure `
  --startup-project .\src\Creavers.Delivery.Infrastructure `
  --output-dir Persistence\Migrations
```

## 17. Docker

```powershell
Set-Location "C:\Users\HP\Documents\ChatGPT\Delivery System"
Copy-Item .\.env.example .\.env
docker compose up --build
docker compose down
```

Replace every placeholder in `.env` before starting Compose. Never commit `.env`.

## 18. Logs and troubleshooting

```powershell
Get-Content ".\tmp\api.out.log" -Tail 100 -Wait
Get-Content ".\tmp\api.err.log" -Tail 100 -Wait
Get-Content ".\tmp\portal.out.log" -Tail 100 -Wait
Get-Content ".\tmp\portal.err.log" -Tail 100 -Wait
```

Restart Android Debug Bridge:

```powershell
adb kill-server
adb start-server
adb devices -l
```

## 19. Git commit and push

```powershell
Set-Location "C:\Users\HP\Documents\ChatGPT\Delivery System"
git status
git add .
git commit -m "fix mobile phone API connectivity and add project command reference"
git push origin main
```

Inspect remotes before pushing:

```powershell
git remote -v
```

Add separate GitLab and GitHub remotes when needed:

```powershell
git remote add gitlab https://gitlab.com/creavers2/all-in-one-delivery-system.git
git remote add github https://github.com/biniamen/delivery_system.git
git push -u gitlab main
git push -u github main
```
