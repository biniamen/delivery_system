# Creavers Delivery Mobile

One Flutter codebase for the two mobile roles in the action plan. Android and iOS are the deployment targets; the browser target provides a fast phone-sized local preview while an emulator is unavailable.

- **Customer:** register by phone with the development OTP, complete a basic profile, search live inventory, choose from private Addis Ababa delivery-address suggestions, build a basket, review order history, and follow the assigned driver's pin and delivery timeline.
- **Driver:** explicitly start foreground location sharing, inspect assigned stops and pickup checklists, and move an order through Accepted, Picked up, and Delivered.

The app uses feature-first folders, typed models, service contracts, a reusable HTTP transport, centralized API errors, dependency injection through constructors, and role-based navigation. Dispatcher accounts are intentionally directed to the Angular portal.

## Structure

```text
lib/
├── app/                    # Root app and session controller
├── core/
│   ├── config/             # Compile-time environment configuration
│   ├── models/             # Typed API models
│   ├── network/            # HTTP transport, API client, safe errors
│   ├── services/           # Auth, catalogue, orders, GPS, location API
│   └── theme/              # Mobile design system
├── features/
│   ├── auth/
│   ├── onboarding/        # Phone, static OTP, and customer profile
│   ├── customer/
│   │   ├── cart/            # Basket state and review screen
│   │   ├── checkout/        # Validated order submission
│   │   └── orders/          # Auto-refreshing customer tracking
│   └── driver/
└── shared/widgets/
```

## Backend address

`API_ORIGIN` is a compile-time value. The default is the Android Emulator host alias `http://10.0.2.2:5080`.

| Target | Recommended value |
| --- | --- |
| Android Emulator | `http://10.0.2.2:5080` |
| iOS Simulator | `http://127.0.0.1:5080` |
| Local connection script | `http://127.0.0.1:5080` |
| Physical phone | `http://<computer-LAN-IP>:5080` |

The generated Android debug/profile manifests allow local clear-text HTTP for prototype testing. Production builds should use HTTPS. Physical-device testing also requires Kestrel to listen on the LAN interface and the firewall to allow the selected development port.

## Run

Start PostgreSQL and the backend first. Then, from this directory:

```powershell
flutter pub get
flutter run --dart-define=API_ORIGIN=http://10.0.2.2:5080
```

### Run from VS Code

Open this `mobile` folder as the workspace. The repository includes `.vscode/settings.json` for the project-local Flutter SDK and two Run/Debug profiles:

- `Creavers Mobile — Web Preview` uses Chrome at `http://localhost:8080`.
- `Creavers Mobile — Android Emulator` uses the Android host alias `10.0.2.2`.

Select a profile in **Run and Debug**, then press `F5`. The Android profile requires an installed Android SDK and a running emulator.

On the Driver screen, tap **Start sharing** and approve the operating-system prompt. The app uses foreground/while-in-use GPS only and stops the stream when the driver stops sharing, signs out, or closes the screen. Browser geolocation requires a secure context; `localhost` is accepted for local development.

The map tile endpoint is configurable:

```powershell
flutter run --dart-define=API_ORIGIN=http://10.0.2.2:5080 --dart-define=MAP_TILE_URL=https://your-tile-provider/{z}/{x}/{y}.png
```

The default OpenStreetMap endpoint is suitable only for light interactive prototype testing and must retain the visible attribution. Use a production tile provider before a pilot rollout.

Use these local demo accounts with the password configured for the backend:

- `customer@demo.creavers.local`
- `driver@demo.creavers.local`

For the currently running local environment, the password is `CreaversDemo!2026`.

To create a new customer, choose **Create customer account**, enter an Ethiopian mobile number, and use the static development code `246810`. The next step collects the customer's full name and date of birth. This code is intentionally development-only and must be replaced with an SMS provider before production.

Checkout suggestions are currently supplied by the local `AddressSuggestionService`, so development searches do not transmit typed customer addresses to a third-party geocoder. Replace that implementation with a contracted production geocoding provider when the deployment environment and privacy terms are approved.

## Verify

```powershell
flutter analyze
flutter test

$env:CREAVERS_TEST_EMAIL = 'customer@demo.creavers.local'
$env:CREAVERS_TEST_PASSWORD = 'CreaversDemo!2026'
dart run tool/backend_connection_check.dart --origin=http://127.0.0.1:5080
```

The command-line check calls `/health/live`, then optionally authenticates when both test credential environment variables are present. It also parses the customer catalogue or the driver's assigned-order list to prove the live API contract matches the app models. It never prints the access token or password.

To verify the complete order handoff against the local demo database:

```powershell
$env:CREAVERS_TEST_PASSWORD = 'CreaversDemo!2026'
dart run tool/full_order_flow_check.dart --origin=http://127.0.0.1:5080
```

This creates one two-line demonstration order, assigns it using dispatcher authorization, confirms it appears for the driver, and confirms customer tracking reports the assignment. It intentionally leaves that assigned demo order available for visual testing.

## Security boundary

The prototype keeps the access token in memory, so closing the app signs the user out. Before a pilot release, add platform secure storage, certificate-backed HTTPS, production signing, and environment-specific configuration. Never hardcode production credentials in the application.
