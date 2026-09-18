# Action plan mapping

## Covered by this foundation

| Plan requirement | Foundation evidence |
| --- | --- |
| API skeleton, roles, order states | Versioned controllers, JWT policies, domain enums and transition rules |
| PostgreSQL model and OpenAPI contracts | EF Core entity configurations and development OpenAPI endpoint |
| Repeatable database setup | Baseline EF Core migration plus idempotent development seed data |
| Angular shell, navigation and UI tokens | Authenticated shell, global design tokens, responsive layout |
| Flutter customer and driver flow | Role-aware navigation, basket, checkout, tracking, driver stop details and audited status actions |
| Dispatcher login and session handling | Login feature, auth service, interceptor, auth/role guards |
| Order queue and order detail base | Live queue, status filtering, totals, timeline, detail page |
| 36 products across six categories | Repeatable catalogue seeder with units, ETB prices and image paths |
| Validation, safe errors and duplicate protection | Application validation, Problem Details handler and unique idempotency index |
| Driver assignment and history | Available-driver endpoint, assignment UI and immutable assignment history |
| Secrets and structured logs | Environment-only secret configuration and `ILogger` event records |
| Tests | Domain order-invariant tests and Angular auth/status component tests |

## Intentionally next

- Add customer order history and persistent secure session storage before pilot use.
- Add real-time queue updates only after the basic refresh workflow is stable.
- Add integration and end-to-end tests with a disposable PostgreSQL database.
- Add presenter reset authorization and prospect-specific branding profiles in Weeks 3-4.

## Week 3 exit gate - Friday, 18 September 2026

| Assigned milestone | Implementation evidence |
| --- | --- |
| Mon 14 Sep - driver receives assigned order and customer address | Assigned-to-me API plus driver home/detail views with customer, address, products, payment and route context |
| Tue 15 Sep - driver accepts only their own assignment | Driver-only transition endpoint, assigned-driver ownership enforcement, Accept action and authorization tests |
| Wed 16 Sep - pickup and delivery updates | Sequential Accepted -> PickedUp -> Delivered state machine, confirmation UI and dispatcher/customer visibility |
| Wed 16 Sep - timestamps and persistent history | Actor, note and UTC timestamp stored for every status; timestamped driver progress card and ordered-history tests |
| Mobile retry safety | Repeating the current transition returns the existing order without duplicating the audit trail |
| Thu 17 Sep - permissions and reassignment safety | Driver-only updates, assigned-driver ownership, reassignment locked after acceptance, and busy-driver/deactivation conflict protection |
| Thu 17 Sep - refresh and recoverable errors | Customer, driver and dispatcher refresh controls with loading, empty, authorization and connection states |
| Fri 18 Sep - complete integration | PostgreSQL-backed Customer -> Dispatcher -> Driver -> Customer confirmation -> Dispatcher acceptance flow |
| Controlled driver onboarding | Dispatcher-only driver registration and activation; no public driver self-registration |
| Customer trust confirmation | Customer receipt confirmation stored as `DeliveryConfirmed` and shown in dispatcher history |
