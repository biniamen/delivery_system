# Google Maps Platform setup

The codebase supports the complete Google Maps feature set required by the delivery flow. Google integration is disabled by default so checkout can still be tested without credentials; enabling it switches on the production map path without removing the OpenStreetMap/local-address fallback.

## Service-to-code map

| Google service | Application use | Credential boundary |
| --- | --- | --- |
| Maps SDK for Android | Customer pin picker, driver/customer live route map and traffic layer | Android-restricted key in `mobile/android/secrets.properties` |
| Maps SDK for iOS | Same native mobile map features for iPhone/iPad | iOS-restricted key in `mobile/ios/Flutter/Secrets.xcconfig` |
| Maps JavaScript API | Dispatcher live fleet map, Advanced Markers, accuracy circles and order route | HTTP-referrer-restricted browser key returned to authenticated dispatchers |
| Places API (New) | Ethiopia-restricted address autocomplete with per-search session tokens | Server key; called only by the backend |
| Geocoding API | Written address to coordinates and selected map pin to readable address | Server key; called only by the backend |
| Routes API | Traffic-aware driving polyline, remaining distance and ETA | Server key; called only by the backend |

The backend endpoints are rate-limited and authorized by role. Customers can geocode checkout addresses and view only their order routes. Drivers can view only assigned routes. Dispatchers can view fleet and order routes. Route results are cached for 30 seconds per driver position to control latency and billable calls.

## Google Cloud configuration

1. Create a dedicated Google Cloud project, attach a billing account, and enable the six APIs listed above.
2. Create four separate API keys. Do not reuse one unrestricted key across platforms.
3. Restrict the server key to the backend's fixed outbound IP addresses and allow only Places API (New), Geocoding API, and Routes API.
4. Restrict the browser key by production and approved development HTTP referrers and allow only Maps JavaScript API.
5. Restrict the Android key to package `com.creavers.creavers_delivery_mobile` and the debug/release SHA-1 fingerprints; allow only Maps SDK for Android.
6. Restrict the iOS key to bundle ID `com.creavers.creaversDeliveryMobile`; allow only Maps SDK for iOS.
7. Create a production Map ID for JavaScript, Android, and iOS styling. `DEMO_MAP_ID` is suitable only for initial integration testing.
8. Configure conservative API quotas, budget alerts, billing alerts, key-usage monitoring, and separate non-production/production projects or keys.

## Backend and dispatcher

For Docker, copy `.env.example` to `.env` and set:

```dotenv
GOOGLE_MAPS_ENABLED=true
GOOGLE_MAPS_SERVER_API_KEY=server-key
GOOGLE_MAPS_BROWSER_API_KEY=browser-key
GOOGLE_MAPS_MAP_ID=production-map-id
```

For the local PowerShell scripts, set the same variables in the current terminal before restart:

```powershell
$env:GOOGLE_MAPS_ENABLED = 'true'
$env:GOOGLE_MAPS_SERVER_API_KEY = '<server-key>'
$env:GOOGLE_MAPS_BROWSER_API_KEY = '<browser-key>'
$env:GOOGLE_MAPS_MAP_ID = '<production-map-id>'
.\scripts\restart-local.ps1
```

The browser key is inherently visible to browsers, so referrer and API restrictions are mandatory. Server keys are never returned to the Angular or Flutter clients.

## Android

Create the ignored secret file and replace the placeholder:

```powershell
Set-Location mobile
Copy-Item android/local.defaults.properties android/secrets.properties
```

```properties
MAPS_API_KEY=YOUR_ANDROID_RESTRICTED_KEY
```

Run the native application:

```powershell
flutter run --dart-define=API_ORIGIN=http://10.0.2.2:5080 --dart-define=GOOGLE_MAPS_ENABLED=true --dart-define=GOOGLE_MAPS_MAP_ID=<production-map-id>
```

## iOS

On macOS, create the ignored configuration from the example:

```bash
cd mobile
cp ios/Flutter/Secrets.xcconfig.example ios/Flutter/Secrets.xcconfig
```

Set `GOOGLE_MAPS_IOS_API_KEY` in that file, then run:

```bash
flutter run --dart-define=API_ORIGIN=http://127.0.0.1:5080 --dart-define=GOOGLE_MAPS_ENABLED=true --dart-define=GOOGLE_MAPS_MAP_ID=<production-map-id>
```

The iOS deployment target is 15, which satisfies the current Flutter Google Maps package requirement. iOS compilation and signing must be validated on macOS with Xcode.

## Operational checks

- Confirm autocomplete is biased to Addis Ababa and predictions resolve to saved coordinates.
- Tap a map point and confirm the readable address is updated while coordinates remain authoritative.
- Assign an order, start driver GPS sharing, and confirm dispatcher/customer/driver route lines update with distance and ETA.
- Verify browser, Android, iOS, Places, Geocoding, and Routes key metrics separately in Google Cloud.
- Test quota exhaustion and provider downtime: the UI should retain the saved location and core order workflow, while presenting a safe retry message.

Never commit `.env`, `android/secrets.properties`, `ios/Flutter/Secrets.xcconfig`, API keys, access tokens, or customer location exports.
