# Backend Integration Analysis

Audit date: 2026-10-08

## 1. Existing architecture

The repository is a small monorepo containing:

- `apps/backend`: Django 5 + Django REST Framework, split into domain apps. Only the `places` domain currently exists.
- `apps/mobile`: Flutter with feature-first Clean Architecture, BLoC, GetIt, GoRouter, Dio, Hive CE and Easy Localization.
- `apps/admin`: Vite + React + TypeScript. It is an admin placeholder, not a customer storefront.
- PostgreSQL is configured for Docker. Local Django execution falls back to SQLite.
- Redis and Celery are configured, but no application tasks exist.
- MinIO is started by Compose, but Django media storage is not connected to it.
- drf-spectacular exposes OpenAPI schema and Swagger UI.

## 2. Available endpoints

| Method | Path | Status | Purpose |
|---|---|---|---|
| GET | `/api/v1/places/` | AVAILABLE | Paginated published places; supports DRF `search` and `ordering`. |
| GET | `/api/v1/places/{id}/` | AVAILABLE | Published place details including services. |
| GET | `/api/schema/` | AVAILABLE | Generated OpenAPI schema. |
| GET | `/api/docs/` | AVAILABLE | Swagger UI. |
| `/admin/` | Django admin | AVAILABLE | Place/service administration after staff login. |

No other public application endpoints are registered in `config/urls.py`.

## 3. Request and response contracts

### Place list

Supported query parameters from the current viewset:

- `search`: matches place name, address or service name.
- `ordering`: `rating`, `name` or `created_at`; prefix with `-` for descending order.
- `page`: DRF page number pagination.

Response shape:

```json
{
  "count": 1,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "Example",
      "description": "",
      "address": "Tashkent",
      "latitude": "41.311081",
      "longitude": "69.240562",
      "rating": "4.8",
      "is_verified": true,
      "services": [
        {"id": 1, "name": "Service", "price": "180000.00", "duration_minutes": 60}
      ]
    }
  ]
}
```

Decimal values are serialized as strings by DRF. The current Flutter model expects numeric `double` values, so an explicit decimal mapping is required before this integration is production-safe.

## 4. Authentication flow

Status: **MISSING**

- Django's built-in session authentication is present only indirectly through installed Django apps/admin.
- DRF has no declared authentication or default permission policy.
- JWT, access/refresh token endpoints, phone authentication and OTP are absent.
- OTP expiry, resend limits and rate limiting are absent.
- Customer roles and ownership rules are absent.
- The mobile secure-storage infrastructure exists, but there is no valid backend token contract to connect it to.

## 5. Existing business logic

### Places and services — PARTIAL

- A place has address, coordinates, rating, verification and publication flags.
- A service belongs to a place and has name, price, duration and active status.
- Public API returns only published places.
- Search and ordering are available.

### E-commerce domains

| Feature | Status | Evidence / gap |
|---|---|---|
| Product categories | MISSING | No category model or endpoint. |
| Products and variants | MISSING | No product, SKU, media or variant model. |
| Inventory | MISSING | No stock ledger or availability logic. |
| Prices and discounts | MISSING | Service price exists, but no product price/discount rules. |
| Cashback / loyalty | MISSING | No model, calculation or API. |
| Search/filter catalog | MISSING | Only place search exists. |
| Favorites | MISSING | No customer identity or favorite relation. |
| Cart | MISSING | No cart models, totals or mutation API. |
| Checkout | MISSING | No checkout orchestration or idempotency contract. |
| Orders | MISSING | No order snapshot, states or history. |
| Delivery addresses/methods | MISSING | No delivery domain. |
| Payments | MISSING | No provider integration or payment state. |
| Customer profile | MISSING | No customer profile API. |
| Notifications | MISSING | Celery exists, but no notification domain/tasks. |

## 6. Missing API functionality

Before the requested marketplace can be integrated, backend contracts are needed for:

1. Phone +998 OTP challenge, verification, refresh and logout.
2. Category tree and category media.
3. Product list/detail, images, variants, stock, prices, discounts and cashback.
4. Server-side search, filters, sort and cursor/page pagination.
5. Authenticated favorites.
6. Server-authoritative cart with inventory validation and totals.
7. Addresses, delivery methods and delivery estimates.
8. Idempotent checkout and order creation.
9. Payment-provider initiation/callback handling after provider approval.
10. Order history and state transitions.
11. Customer profile, loyalty and notification preferences.
12. Notification feed and read state.

## 7. Compatibility and security risks

- The current product vision is a cosmetics shop while the existing data model is a map of cosmetic service providers. This is a domain mismatch, not a simple UI rename.
- Mobile decimal parsing is incompatible with the current DRF decimal representation.
- Mobile adds a bearer token when present, but backend does not validate bearer tokens.
- No permission defaults are configured; new write endpoints must never inherit permissive defaults accidentally.
- `CORS_ALLOW_ALL_ORIGINS` is enabled in debug. Production origins need an allowlist.
- No throttling, audit trail, structured logging or health endpoint exists.
- MinIO credentials exist in infrastructure but media delivery is not configured in Django.
- Prometheus currently scrapes only itself, not Django or Celery.
- Compose uses floating `latest` image tags for MinIO/Prometheus, which reduces reproducibility.
- There is no production settings split, HTTPS enforcement, secure cookie policy or secret manager integration.
- There is no backup evidence or production database connection in this workspace. Any future production migration requires a verified backup first.

## 8. Recommended integration strategy

1. Preserve the existing `places` app as a separate service-provider domain.
2. Add bounded Django apps rather than expanding `places`: `accounts`, `catalog`, `favorites`, `cart`, `orders`, `delivery`, `payments`, `notifications`.
3. Agree on product/variant/inventory and pricing rules before migrations.
4. Implement OpenAPI-first contracts and generate/validate clients against the schema.
5. Introduce JWT/OTP only after the SMS provider, expiry, retry and throttling rules are approved.
6. Keep backend totals authoritative. Mobile/web may show optimistic quantity changes only with rollback.
7. Build mobile features using the existing Clean Architecture conventions.
8. Add a separate customer web app; do not turn the current admin placeholder into the storefront without an explicit migration decision.

## Capability summary

- Can implement immediately without inventing backend behavior: design tokens, reusable accessible UI, navigation shell, translated empty/loading/error states, client validation, place browsing fixes, contract tests and development fixtures isolated from production.
- Requires backend work: all commerce, authentication, profile, loyalty and notification features.
- Requires product/provider decisions: OTP SMS provider, payment provider, delivery rules, cashback/discount stacking, inventory reservation and order state machine.

