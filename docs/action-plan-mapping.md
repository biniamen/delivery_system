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
