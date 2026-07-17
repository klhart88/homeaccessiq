# HomeAccessIQ

Multi-state down-payment-assistance and homebuyer-program matching tool, part of the SmartIQ family (alongside AreaIQ).

**Backend:** Supabase project `homeaccessiq` (org: SmartIQ Realty) — isolated per the SmartIQ family pattern, not shared with other apps.
**Hosting:** GitHub Pages, static site (no build step) — same deploy pattern as AreaIQ.

## Status

Scaffolding stage. Supabase schema is live (11 tables — see `/schema` reference in project docs). Repo structure and reused modules in place. Matching engine and buyer intake form not yet built.

## What's reused from AreaIQ (per repo audit)

- `js/geocode.js` — address geocoding, not state-specific
- `js/census-block.js` — FCC census block lookup
- `js/cache.js` — browser TTL cache — **scoped to non-sensitive reference data only** (schools, tax rates, program metadata). Buyer eligibility data (income, occupation, veteran status) is never cached here — it lives only in Supabase, RLS-locked.

## What's new (no AreaIQ equivalent)

- `js/supabaseClient.js` — Supabase JS client init
- `js/stateRegistry.js` — replaces AreaIQ's hardcoded `if (state !== 'IN')` pattern with a real, queryable state registry (`states` table), so adding a state is a data operation, not a code change across N files
- Matching engine, buyer intake form — not yet built (next phase)

## Key decisions carried over from planning (see project checklist for full detail)

- Multi-state is v1, not a single-state MVP
- Eligibility data never touches EmailJS/Zapier — only `lead_captures` (contact-only) uses those channels
- Agent visibility into buyer profiles is scoped to buyers who submitted a lead capture, not all tool users
- Deterministic rule matching (six rule types) — no free-text/LLM interpretation needed for v1

## Local development

No build step. Open `index.html` directly, or serve the directory with any static file server. Supabase JS client loads via CDN (see `index.html`).
