# Target Architecture

## Current topology

```text
Flutter mobile ──Dio──> Django REST API ──> PostgreSQL
      │                    │
 Hive/Secure Storage      Redis/Celery
                           │
React admin               MinIO (not wired yet)
```

## Mobile

Retain Flutter and the established feature-first Clean Architecture:

```text
presentation (BLoC event/state)
             │
             v
domain (entities, repository contracts, use cases, Failure)
             ^
             │
data (Dio/Hive data sources, Freezed DTOs, repository implementations, Exception)
```

- GetIt owns dependency composition.
- GoRouter owns top-level and nested navigation.
- Dio owns remote transport; interceptors must redact credentials.
- Hive CE stores typed offline objects.
- flutter_secure_storage stores tokens only.
- shared_preferences stores simple preferences only.
- Easy Localization owns every user-visible static string.
- Server data is not duplicated in unrelated global stores.

## Backend

Keep Django/DRF and add bounded domain apps. Shared business rules belong in application services, not serializers or views. Orders must persist immutable price/product snapshots. Inventory and totals are server-authoritative. Checkout must use an idempotency key.

## Web

The current React app is an admin shell. Recommended topology is:

```text
apps/admin     existing internal administration UI
apps/web       future customer storefront (Next.js + TypeScript)
packages/      generated API types, validation and design tokens where sharing is practical
```

Creating `apps/web` is deferred until its SEO/rendering and deployment requirements are accepted.

## Design system

The initial tokens use premium neutral surfaces and pink accents. Components must be semantic, accessible, responsive and independent of backend fixtures. Mobile and web may share token values and behavior specifications, but not framework-specific widget code.

