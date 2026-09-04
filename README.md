# Creavers Supermarket Delivery

A professional foundation for the reusable supermarket-delivery prototype: ASP.NET Core 10 LTS, PostgreSQL, an Angular dispatcher portal, and a Flutter customer/driver client.

## What is ready

- Clean backend boundaries for Domain, Application, Infrastructure, and API.
- Customer, Dispatcher, Driver, and Store Admin roles with enforced endpoint policies.
- Supermarket inventory management for product details, prices, stock quantities, and customer-facing availability.
- Customer phone onboarding with Ethiopian-number validation, development OTP verification, name, and date of birth.
- Catalogue endpoints and a repeatable seed of 36 realistic products in six categories.
- Server-side stock reservation, totals, idempotent order submission, guarded status transitions, and audit history.
- Responsive dispatcher login, live order queue, order detail, totals, delivery timeline, and driver assignment.
- Separate `.ts`, `.html`, and `.css` files for every Angular component, with dedicated `models`, `services`, `guards`, and `interceptors` folders.
- Role-aware Flutter mobile app with customer basket, checkout, live order tracking, and detailed driver assignment/status workflows.
- A complete customer → dispatcher → driver flow with automatic dispatcher queue refresh and audited delivery transitions.
- Permission-aware foreground driver GPS sharing, a five-second dispatcher fleet map, assigned-order load summaries, and an authorized customer driver map.
- Compact mobile product search, category filters, live stock cues, basket controls, verified-phone checkout, persistent order history, and delivery tracking.
- Environment-only secrets, safe API errors, rate-limited login, OpenAPI, health check, unit-test baselines, Dockerfiles, and Compose.

## Repository map

```text
.
├── backend/
│   ├── src/
│   │   ├── Creavers.Delivery.Domain/
│   │   ├── Creavers.Delivery.Application/
│   │   ├── Creavers.Delivery.Infrastructure/
│   │   └── Creavers.Delivery.Api/
│   └── tests/Creavers.Delivery.UnitTests/
├── frontend/dispatcher-portal/
│   └── src/app/
│       ├── core/{models,services,guards,interceptors}/
│       ├── features/{auth,orders,drivers,products}/
│       ├── layout/
│       └── shared/components/
├── mobile/                 # Flutter Android/iOS customer and driver client
├── docs/
├── scripts/
└── docker-compose.yml
```

See [architecture](docs/architecture.md) for boundaries and security decisions, and [action-plan mapping](docs/action-plan-mapping.md) for plan-to-code traceability.

## Start with Docker

Prerequisites: Docker with Compose.

1. Copy `.env.example` to `.env`.
2. Replace every placeholder with a long local-only value. The JWT key must contain at least 32 characters.
3. Start the controlled demo environment:

   ```powershell
   docker compose up --build
   ```

4. Open `http://localhost:4200`. Dispatchers sign in with `dispatcher@demo.creavers.local`; supermarket admins use `storeadmin@demo.creavers.local`. Use the respective password assigned in `.env`.
5. Development OpenAPI JSON is available through the API container at `/openapi/v1.json`; liveness is `/health/live`.

The Compose database is persisted in the named `creavers-postgres-data` volume. The project does not include or process live payment details.

## Run without Docker

Backend prerequisites: .NET 10 SDK and PostgreSQL 18 (or a compatible supported PostgreSQL release).

```powershell
$env:ConnectionStrings__Postgres = 'Host=localhost;Port=5432;Database=creavers_delivery;Username=creavers_app;Password=<local-password>'
$env:Jwt__SigningKey = '<at-least-32-random-characters>'
$env:DemoAccounts__DispatcherPassword = '<demo-password>'
$env:DemoAccounts__CustomerPassword = '<demo-password>'
$env:DemoAccounts__DriverPassword = '<demo-password>'
$env:DemoAccounts__StoreAdminPassword = '<demo-password>'
dotnet run --project backend/src/Creavers.Delivery.Api
```

Frontend prerequisites: Node.js `20.19.x` or another version supported by Angular 21, with Corepack enabled for pnpm 11.

```powershell
corepack enable
corepack prepare pnpm@11.19.0 --activate
Set-Location frontend/dispatcher-portal
pnpm install
pnpm start
```

The local Angular environment calls `http://localhost:5080/api/v1`.

The development maps use OpenStreetMap raster tiles with visible attribution. Configure a managed/self-hosted tile URL before production traffic; do not add bulk download or offline-prefetch behavior to the public tile service.

## Run the mobile client

Install Flutter and the Android SDK, start the backend, then run the app from the separate mobile workspace:

```powershell
Set-Location mobile
flutter pub get
flutter run --dart-define=API_ORIGIN=http://10.0.2.2:5080
```

`10.0.2.2` is the Android Emulator alias for the host computer. See the [mobile README](mobile/README.md) for iOS Simulator, physical-device, test, and connection-check settings.

Drivers start and stop location sharing themselves. The prototype requests only while-in-use permission and does not declare background-location access.

In Development, customer registration uses the static OTP `246810`. The API returns that code only when `CustomerOnboarding:ExposeDevelopmentCode` is enabled. Disable development-code exposure and connect a real SMS provider before any pilot or production deployment.

## Verification

```powershell
./scripts/check-foundation.ps1
dotnet test backend/Creavers.Delivery.slnx
Set-Location frontend/dispatcher-portal
pnpm test
pnpm build:production
```

The repository check confirms that each Angular component has external HTML/CSS files and that the catalogue contains at least 36 seeded records.

## Database migrations

The reviewed migrations include the initial model and the store-admin/inventory/customer-onboarding extension. Development initialization applies pending migrations and then performs idempotent demo seeding. Create later migrations deliberately as the model evolves:

```powershell
Set-Location backend
dotnet tool restore
dotnet ef migrations add DescribeTheChange --project src/Creavers.Delivery.Infrastructure --startup-project src/Creavers.Delivery.Infrastructure --output-dir Persistence/Migrations
```

Never commit `.env`, real passwords, connection strings, tokens, or prospect/customer data.
