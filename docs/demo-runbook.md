# Creavers delivery prototype demo runbook

## Demo scope

This runbook validates the Week 3 exit gate: customer order, dispatcher assignment, driver acceptance and delivery, customer receipt confirmation, and final dispatcher visibility. Driver accounts are created only by an authenticated dispatcher.

## Pre-demo technical check

From the repository root:

```powershell
.\scripts\restart-local.ps1
```

Confirm these addresses respond:

- Mobile preview: `http://localhost:8080`
- Dispatcher portal: `http://localhost:4200`
- API health: `http://localhost:5080/health/live`

Set the local demo password and run the complete automated readiness check:

```powershell
$env:CREAVERS_TEST_PASSWORD = '<local-demo-password>'
.\scripts\check-demo-readiness.ps1
```

Expected final line:

```text
delivery-flow=passed status=DeliveryConfirmed ... customer=visible dispatcher=visible
```

## CEO demonstration - internal acceptance

Target duration: 8 to 10 minutes.

1. Open the mobile app and show customer phone onboarding. Use the development OTP displayed by the prototype.
2. Browse products, add products to the cart, select a recommended/map delivery address, and place the order.
3. Open the dispatcher portal and show the new order in the queue.
4. Open **Driver accounts**. Explain that drivers are verified and registered by dispatch, not through public self-registration.
5. Open the order and assign an available driver.
6. Sign in to the mobile app as that driver. Open the assignment, accept it, start foreground location sharing, mark pickup, and mark delivery.
7. Return to the customer tracking screen. Show the map, delivery history, and select **Confirm delivery**.
8. Refresh the dispatcher order detail and show **Confirmed received** with the complete audit timeline.
9. Show the live-driver map and explain the Google Maps production integration plus development fallback.

CEO acceptance checks:

- The order appears once after submission or retry.
- Only an available driver can be assigned.
- Only the assigned driver can change delivery status.
- Statuses occur in order and include actor/timestamp history.
- Only the owning customer can confirm receipt.
- Dispatch sees the final customer confirmation.
- Driver deactivation is blocked while an active order is held.

## Client demonstration - business story

Target duration: 6 to 8 minutes. Reset to clean demo accounts and sample data first.

1. Start with the customer value: quick onboarding, clear catalogue, cart, address recommendation, map pin and transparent total.
2. Show operational control: order queue, controlled driver accounts, manual assignment and live map.
3. Show delivery execution: driver assignment, acceptance, pickup, route and delivered action.
4. Finish with trust: customer tracking, receipt confirmation and a shared audit trail visible to operations.

Keep technical configuration, API keys, development passwords and internal logs out of the client presentation. Describe payments, OTP and Google Maps as prototype integrations unless production credentials and services have been approved.

## Recovery during a demonstration

- If a page is stale, use its Refresh action before restarting anything.
- If the mobile preview changed, press `Ctrl+F5` once.
- If the stack is unavailable, run `.\scripts\restart-local.ps1` from the repository root.
- If a driver is unavailable, complete their active test delivery or select another active driver.
- Keep one pre-created customer, dispatcher and driver demo account ready as a fallback.
