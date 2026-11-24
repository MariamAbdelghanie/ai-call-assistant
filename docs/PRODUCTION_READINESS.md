# CALLORA production-readiness plan

This document records the staged path from the current single-owner prototype to a secure, multi-user product. It intentionally distinguishes implemented behavior from work still required.

## Current repository findings

- Flutter mobile panel currently enters the home shell after a welcome screen; there is no user sign-in/sign-up flow.
- Mobile API client sends a shared `X-API-Token` and calls `/logs`, `/api/config`, and related endpoints. This is not per-user authentication or tenant isolation.
- Flutter stores the server URL and API token in SharedPreferences. Production credentials/session tokens must not be stored this way.
- Python `CalendarAndNotesService` initializes a single Google Calendar identity and a single Firebase Admin Firestore connection from environment credentials.
- The assistant's work-hour defaults in the web dialer are 09:00–17:00; the product requirement is 08:00–20:00.
- The existing Flutter app already supports light, dark, and system theme modes. The design token layer has been updated on this branch to a graphite/Storm Grey/Safety Orange visual system; individual screens still need a full component-level redesign.

## Target architecture

1. Firebase Authentication (email/password and Google sign-in) for account identity.
2. Backend verifies Firebase ID tokens on every protected request. Never trust a user ID supplied in request JSON or query parameters.
3. Firestore documents are tenant-scoped under `users/{uid}/...`, or carry a server-enforced `ownerUid` field. All reads/writes enforce the authenticated UID.
4. Google Calendar uses per-user OAuth consent and refresh-token storage encrypted server-side. Do not use one shared service-account calendar for all customers.
5. LiveKit SIP routing maps each provisioned inbound number/trunk to a tenant using trusted server-side SIP metadata. Never accept tenant identity from caller speech or client input.
6. Secrets live in a managed secret store/environment, not source control or mobile assets. Use HTTPS, request validation, rate limits, audit events, and redacted logs.
7. Mobile session tokens use platform secure storage. Firestore client access remains denied unless a carefully reviewed, UID-scoped ruleset is intentionally introduced; backend Admin SDK access must still enforce tenant ownership in application code.

## Delivery sequence

### Stage 1 — Product foundation
- Replace the shared API token model with Firebase Auth and verified backend bearer tokens.
- Add sign-in, sign-up, password reset, sign-out, session restoration, and account deletion.
- Add per-user profile, assistant settings, locale/timezone, and 08:00–20:00 working-hours settings.
- Add tenant isolation tests proving user A cannot read or mutate user B's calls, configuration, appointments, or integrations.

### Stage 2 — Integrations
- Implement per-user Google Calendar OAuth connect/disconnect and token refresh.
- Add booking safeguards: timezone-aware working hours, availability recheck immediately before event creation, idempotency, explicit caller confirmation, and conflict handling.
- Provision and map phone/SIP numbers to users; validate provider webhooks and SIP metadata.

### Stage 3 — Production operations
- HTTPS-only deployment, managed secrets, backups, retention/deletion workflows, monitoring, alerting, and disaster recovery.
- Consent and disclosure flow for callers; review applicable call-recording, privacy, consumer, and telecom laws for each launch market.
- Google Play Data safety, privacy policy, account deletion URL/process, permission declarations, and closed testing.

### Stage 4 — UI redesign
- Redesign welcome, auth, dashboard, calls, call detail, appointments, assistant settings, integrations, profile, billing, and empty/error/loading states.
- Keep light/dark/system mode and persist the preference.
- Use consistent spacing, typography, semantic colors, accessibility contrast, responsive layouts, and production-grade form validation.

## Important non-goals for a first UI pass

A polished login screen is not proof of secure authentication. A connected calendar badge is not proof of per-user OAuth. A call record displayed in the UI is not proof that SIP routing is correctly tenant-scoped. These require backend implementation and integration tests before public release.
