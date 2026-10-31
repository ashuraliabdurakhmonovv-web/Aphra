# Implementation Plan

## Stage 1 — Discovery and contracts

Status: **COMPLETED**

- Repository and backend audit.
- Verified endpoint inventory.
- Compatibility risks and missing-domain matrix.
- Architecture and integration strategy.

## Stage 2 — Foundation

Status: **PARTIAL**

Already available:

- Flutter Clean Architecture foundation.
- BLoC event/state, GetIt, GoRouter and Dio.
- Hive CE, secure storage and preferences boundaries.
- Uzbek/Russian/English localization.
- Basic loading/error/empty rendering.

Next:

1. Formalize design tokens and reusable mobile states/buttons/cards.
2. Expand navigation to `Home | Catalog | Favorites | Cart | Profile`.
3. Fix verified place decimal mapping and add repository/BLoC tests.
4. Add redacted logging, cancellation and safe retry policy to Dio.
5. Decide customer web application architecture.

## Stage 3 — Catalog

Status: **BLOCKED BY BACKEND DOMAIN CONTRACT**

Sequence after approval:

1. Category/product/variant/media/inventory models and migrations.
2. Read-only catalog API with filter/search/pagination.
3. OpenAPI contract tests.
4. Flutter category, product grid, details, search and filter features.
5. Customer web catalog with SEO product pages.

## Stage 4 — Shopping

Status: **BLOCKED BY AUTH, INVENTORY AND PRICING RULES**

Implement favorites, cart, checkout and orders only after server-authoritative contracts exist. Payment integration additionally requires an approved provider and test environment.

## Stage 5 — Customer account

Status: **BLOCKED BY OTP/SMS AND CUSTOMER CONTRACTS**

Implement phone authentication, profile, addresses, loyalty and notifications after provider and security rules are approved.

## Stage 6 — Validation and release

- Backend unit/API tests and migration checks.
- Flutter unit/widget/integration tests and Android/iOS build checks.
- Web lint/typecheck/unit/E2E/build checks.
- Dependency and security review.
- Production settings, observability, backups, rollback and deployment runbooks.

## Required decisions

1. Is the final product a cosmetics marketplace, a service-provider map, or both?
2. Product variant/SKU and inventory reservation rules.
3. Discount and cashback calculation/stacking rules.
4. OTP/SMS provider and abuse limits.
5. Delivery geography, pricing and providers.
6. Payment provider and reconciliation requirements.
7. Customer web hosting/SEO requirements.
8. Production infrastructure and backup ownership.

