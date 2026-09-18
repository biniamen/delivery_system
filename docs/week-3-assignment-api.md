# Week 3 assignment and delivery-status API

This contract supports the 14-16 September 2026 assignment, driver-acceptance, pickup and delivery milestones. In the user interface, **driver** is the customer-facing term for the action plan's **courier** role.

## Workflow

```text
Customer creates order (New)
  -> Dispatcher selects an available driver
  -> Dispatcher assigns order (Assigned)
  -> Assigned driver receives the order
  -> Assigned driver accepts it (Accepted)
  -> Driver confirms supermarket pickup (PickedUp)
  -> Driver confirms customer delivery (Delivered)
  -> Customer confirms receipt (DeliveryConfirmed)
  -> Dispatcher and customer see every persisted milestone
```

## Dispatcher endpoints

### List and register driver accounts

```http
GET /api/v1/drivers
POST /api/v1/drivers
Authorization: Bearer <dispatcher-token>
```

The create request contains `displayName`, `email`, `phoneNumber`, and `temporaryPassword`. Public driver registration is intentionally disabled. The dispatcher verifies the driver, creates the account, and shares the temporary password privately.

```http
PUT /api/v1/drivers/<driver-id>/status
Authorization: Bearer <dispatcher-token>
Content-Type: application/json

{ "isActive": false }
```

Deactivated drivers cannot sign in or receive new assignments. A driver holding an active delivery cannot be deactivated until the delivery is completed or reassigned.

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

### Update an assigned delivery

```http
POST /api/v1/orders/<order-id>/transitions
Authorization: Bearer <driver-token>
Content-Type: application/json

{
  "status": "Accepted",
  "note": "Delivery accepted"
}
```

The same endpoint is called sequentially with `Accepted`, `PickedUp`, and `Delivered`.

Rules:

- Only the assigned driver can update the order.
- The domain state machine rejects skipped and backward transitions.
- Every successful milestone stores its actor, UTC timestamp and audit note in status history.
- Retrying the current target state is idempotent, returns the current order and does not duplicate history.
- Dispatcher order details and customer tracking read the same persisted status history.

## Customer confirmation endpoint

After the driver records `Delivered`, the customer who placed the order confirms receipt:

```http
POST /api/v1/orders/<order-id>/delivery-confirmation
Authorization: Bearer <customer-token>
```

The resulting status is `DeliveryConfirmed`. The confirmation records the customer and UTC timestamp, is visible to dispatch, and is idempotent for safe mobile retries. Another customer or a confirmation before `Delivered` is rejected.

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

The flow check validates creation, availability, assignment, safe assignment retry, assigned-order visibility, acceptance, pickup, delivery, customer confirmation, ordered milestone timestamps, safe retries, and final status visibility for both customer and dispatcher.
