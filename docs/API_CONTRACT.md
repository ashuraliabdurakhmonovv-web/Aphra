# API Contract

This document records only verified endpoints. Planned contracts must not be consumed by clients until implemented and present in OpenAPI.

## Verified API

Base path: `/api/v1`

### List places

`GET /places/`

Query parameters: `page`, `search`, `ordering`.

Success: DRF page object containing `Place` records. Anonymous access currently works because no restrictive DRF permission is configured.

### Place details

`GET /places/{id}/`

Success: one published `Place`. Unpublished and unknown IDs return `404`.

### Place mapping

| API field | Flutter field | Conversion |
|---|---|---|
| `id` | `id` | integer |
| `name` | `name` | direct |
| `address` | `address` | direct |
| `latitude` | `latitude` | decimal string to double |
| `longitude` | `longitude` | decimal string to double |
| `rating` | `rating` | decimal string to double |
| `is_verified` | `isVerified` | snake_case mapping |

## Planned namespaces — not implemented

The following namespaces are reserved in planning only and are not valid endpoints yet:

- authentication
- catalog/categories/products
- favorites
- cart
- checkout/orders
- addresses/delivery
- payments
- profile/loyalty
- notifications

Their exact paths and payloads will be added after domain rules are approved and backend implementations are tested.

## Error contract recommendation

Future endpoints should return a stable envelope with machine-readable `code`, user-safe `detail`, optional field errors and a correlation ID. This is a recommendation, not an existing backend behavior.

