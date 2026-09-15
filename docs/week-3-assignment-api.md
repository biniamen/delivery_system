# Week 3 driver-assignment API

This contract supports the 14-15 September 2026 assignment and driver-acceptance milestones. In the user interface, **driver** is the customer-facing term for the action plan's **courier** role.

## Workflow

```text
Customer creates order (New)
  -> Dispatcher selects an available driver
  -> Dispatcher assigns order (Assigned)
  -> Assigned driver receives the order
  -> Assigned driver accepts it (Accepted)
```

## Dispatcher endpoints

### List available drivers

```http
GET /api/v1/drivers/available
Authorization: Bearer <dispatcher-token>
```

Only active drivers without another active delivery are returned. When editing an existing assignment, include the order so its current driver remains selectable:

```http
GET /api/v1/drivers/available?forOrderId=<order-id>
```

### Assign or reassign an order

```http
PUT /api/v1/orders/<order-id>/assignment
Authorization: Bearer <dispatcher-token>
Content-Type: application/json

{
  "driverId": "<driver-id>"
}
```

Rules:

- The target account must be an active Driver.
- The driver must not hold another active delivery.
- Assignment and reassignment are allowed only while the order is `New` or `Assigned`.
- Retrying the same `PUT` with the same driver is idempotent and does not duplicate audit history.
- Successful assignment moves a new order to `Assigned`.
- A conflicting load or status returns `409 Conflict` with safe Problem Details.

Every order detail response includes `assignmentHistory` entries with `driverId`, `assignedByUserId`, and `assignedAtUtc`.

## Driver endpoints

### List the signed-in driver's orders

```http
GET /api/v1/orders/assigned-to-me
Authorization: Bearer <driver-token>
```

### Read an assigned order

```http
GET /api/v1/orders/<order-id>
Authorization: Bearer <driver-token>
```

A driver receives `403 Forbidden` for an order assigned to somebody else.

### Accept an assigned order

```http
POST /api/v1/orders/<order-id>/transitions
Authorization: Bearer <driver-token>
Content-Type: application/json

{
  "status": "Accepted",
  "note": "Delivery accepted"
}
```

Only the assigned driver can accept the order. The domain state machine rejects skipped or repeated transitions and stores the actor and timestamp in status history.

## Verification

Run the backend suite:

```powershell
.\tmp\dotnet-sdk-10\dotnet.exe test .\backend\Creavers.Delivery.slnx --no-restore
```

With the local stack running, execute the PostgreSQL-backed workflow:

```powershell
$env:CREAVERS_TEST_PASSWORD = '<local-demo-password>'
Set-Location .\mobile
dart run .\tool\full_order_flow_check.dart --origin=http://127.0.0.1:5080
```

The flow check validates creation, availability, assignment, safe assignment retry, assigned-order visibility, driver acceptance, and customer status visibility. It completes the test delivery afterward so the driver becomes available for another run.
