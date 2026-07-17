# HomeAccessIQ — Scaffolding Checklist (v0.1)

**Purpose:** One place that reconciles the original plan, the AreaIQ repo audit, and the eligibility-rule spec — so no thread gets dropped when work starts. Each item notes *why* it's here and what it depends on.

---

## Phase 0 — Decisions to close before touching code

These aren't code tasks — they're open questions the audit and spec surfaced. Closing them now prevents rework later.

- [ ] **Confirm hosting stack.** Original plan assumed Vercel; AreaIQ is actually GitHub Pages (static, no backend). Since HomeAccessIQ needs a real backend (Supabase) regardless, decide: Vercel (easier to pair with Supabase, serverless functions if needed) vs. GitHub Pages + Supabase client-side only. *Depends on: nothing — decide first, everything else assumes an answer.*
- [ ] **Confirm state list for v1 launch.** Multi-state is the target architecture, but which states actually get data curated first? (Not a re-litigation of the multi-state decision — just: which 2-3 states populate the first tangible build.)
- [ ] **Decide the PII/compliance boundary explicitly.** AreaIQ's actual precedent leans toward *more* PII exposure than assumed (email/name/phone/notes through EmailJS + Zapier + Airtable). HomeAccessIQ handles income/occupation/veteran-status — meaningfully more sensitive. Decide now: does *any* eligibility data touch EmailJS/Zapier, or does that channel stay limited to contact-only lead capture, with eligibility data living only in Supabase? *This decision shapes the schema (Phase 3) and the intake form (Phase 5), so it can't be deferred into either.*
- [ ] **Decide credential handling before the first commit.** Don't inherit AreaIQ's plaintext-keys-in-repo pattern. Decide: environment variables + `.gitignore`, a secrets manager, or platform-native env config (Vercel/Supabase project settings). Trivial to do right from commit #1, expensive to retrofit.

---

## Phase 1 — Repo & infra setup (mechanical, low-risk)

- [ ] Fork/create new repo (not a literal GitHub fork, given the backend gap — a fresh repo seeded from AreaIQ's reusable files is cleaner)
- [ ] Set up `.gitignore` and environment variable handling per Phase 0 decision *before* copying any config files over
- [ ] Stand up new, isolated Supabase project (separate from other SmartIQ apps, per existing family pattern)
- [ ] Connect chosen hosting platform per Phase 0 decision
- [ ] Set up EmailJS instance — new keys, not reused from AreaIQ (separate app, separate credential exposure surface)

---

## Phase 2 — Carry over from AreaIQ (verbatim or near-verbatim)

Confirmed reusable by the audit — copy, adapt naming/branding, move on without re-litigating:

- [ ] `geocode.js` — address geocoding (Census/Nominatim), not state-specific
- [ ] `census-block.js` — FCC census block lookup
- [ ] `cache.js` — browser TTL cache, but **scope its use** to genuinely cacheable reference data only (see Phase 0 PII decision — do not cache eligibility profiles here)
- [ ] Lead-capture UI shell (`leadcapture.js` structure) — reuse the two-flow pattern (results / question), but re-scope what data flows through it per the Phase 0 PII decision
- [ ] Compare-up-to-3 UX shell (`compare.js`/`compare.html`) — optional, only if program-comparison view is in scope

---

## Phase 3 — Net-new build (the real work; nothing to fork)

- [ ] **Supabase schema**, incorporating the eligibility-rule spec's six rule types (`income_threshold`, `geographic_scope`, `occupation_membership`, `buyer_status`, `employer_criteria`, `financial_underwriting`) plus the separate `program_requirements` table (closing-gate items, not matching filters)
- [ ] `geo_lookup_table` implementation — county-level income tables, purchase price caps; needs to support the multi-scope reality confirmed earlier (state/county/city-bound, employer-bound, nationally-available-but-AMI-restricted)
- [ ] Occupation taxonomy table (versioned, maintained — not a hardcoded enum, per spec)
- [ ] **State registry**, replacing AreaIQ's hardcoded `if (state !== 'IN')` pattern module-by-module. AreaIQ's `schools.js`/`tax.js` pattern (state check + `fileMap` per state) is structurally right but not data-driven — build it as a real registry so adding a state is a data operation, not a code change in N files.
- [ ] Buyer profile data model — two location fields (current residence vs. purchase location), per the residency-vs-purchase-location scenario confirmed earlier
- [ ] Rule-dependency evaluation order in the matching engine (e.g., occupation resolved before buyer-status, since exemptions reference other rules' outcomes)
- [ ] Data retention/deletion policy for sensitive profile fields (income, occupation, veteran/disability status) — flagged in the original plan review, still not written
- [ ] Disclaimer language (non-lending/non-advice framing) — flagged originally, still not drafted

---

## Phase 4 — Data curation (manual for v1, per earlier decision)

- [ ] Curate 3-5 real programs across **at least 2-3 different states** (updated from the original single-state assumption, now that multi-state is v1)
- [ ] Populate `last_verified_date` and `funding_status` for each from day one — not a later add-on
- [ ] Confirm at least one example of each of the three geographic-scope types (state/county-bound, employer-bound, nationally-AMI-restricted) is represented in the initial data set, so the matching engine gets exercised against all three before scaling up

---

## Phase 5 — First tangible result

- [ ] Buyer-profile intake form (with the two location fields, occupation selector against the taxonomy, income entry)
- [ ] Real match result rendering against the hand-loaded multi-state program set
- [ ] Sanity-check: run the Indiana-resident-buying-in-Tennessee scenario against real data to confirm the matching logic behaves as discussed

---

## Explicitly deferred (not v1, but logged so they don't get lost)

- Stacking calculator (`stackable_with` field can be captured in schema now; UI/logic deferred)
- Scraping/automated data acquisition (manual curation confirmed for v1)
- LLM-assisted eligibility interpretation (deterministic rules sufficient per spec — revisit only if a program is found that doesn't fit the six rule types)
