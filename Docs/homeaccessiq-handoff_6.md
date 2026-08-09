# HomeAccessIQ — Project Handoff #6
**Supersedes:** `Docs/homeaccessiq-handoff_5.md` (kept for history; this doc reflects current state as of 2026-08-01, afternoon). Read this one first.

**Purpose:** Down-payment-assistance / homebuyer-program matching tool for Kelvin Hart (SmartIQ Realty / Fathom Realty). **Tagline (locked):** "Uncover funding opportunities and buyer advantages for homeownership with confidence and clarity"

---

## Status since handoff #5 — the big picture

Handoff #5 flagged the hardcoded-IHCDA caveat bug as the top-priority structural fix, per the curation strategy's rule that structural design/stability takes precedence over curation velocity. This session closed that gap end to end: the code was fixed, the data flag that had been rolled back in a prior session was safely reinstated, and the fix was verified both in isolation and against a live intake run.

1. **Root cause confirmed and fixed in `matchingEngine.js`.** `targetedTractCaveat()` — the shared function behind the targeted-census-tract caveat — had "IHCDA" hardcoded into all four of its returned messages and its source-note prefix. It's shared across any program in any state that sets `targeted_lookup_table` on its `rule_config`, so it broke the moment FL Assist/FL HLP started using that path.
2. **`targeted_lookup_table` reinstated for FL Assist and FL HLP** via migration, reversing the hotfix rollback from the prior session (handoff #4) now that the underlying bug is fixed.
3. **Fix verified three ways**: an isolated unit test against the function directly (Florida buyer → "Florida Housing"; Indiana buyer → "IHCDA," corroboration clause intact), a database query confirming the migration actually landed (4 rows, exactly as expected), and a live intake retest against a real Miami-Dade address showing the correct agency name in the app itself.

---

## The bug and the fix

**Root cause:** `targetedTractCaveat()` in `matchingEngine.js` is a shared code path — invoked from both `evaluateIncomeThreshold` and `evaluateFinancialUnderwriting` whenever a rule's `rule_config.targeted_lookup_table` is set. It was originally written for IHCDA's 17-county targeted-tract program, with "IHCDA" written directly into every caveat message. That was invisible while Indiana was the only state using this path. It broke the first time FL Assist/FL HLP set `targeted_lookup_table` (handoff #3/#4), surfacing "verify with IHCDA" on Florida results — the bug that prompted the hotfix rollback two sessions ago.

**Fix applied:**
- Added a `STATE_HOUSING_AGENCY_NAMES` map (`IN: 'IHCDA'`, `FL: 'Florida Housing'`, `KY: 'Kentucky Housing Corporation'`) and a `housingAgencyLabel(stateCode)` helper that falls back to a generic-but-accurate label for any unmapped state, rather than guessing wrong the way the original hardcoding did.
- `targetedTractCaveat()` now resolves the agency from `buyer.purchase_state` instead of a literal string, in all four returned messages and the source-note prefix.
- Added an optional `rule_config.targeted_tract_corroboration_note` field so state-specific corroboration detail (e.g. IHCDA's "two independent documents" claim) lives in that program's data, not hardcoded into the shared function. This keeps the function itself state-agnostic going forward — the design requirement the curation strategy calls out explicitly.
- Rewrote the block comment above the function to document the bug, the fix, and the rule for future states (add a map entry; never hardcode a state/agency name into a shared code path).

**Known follow-up (not yet done, low priority):** IHCDA's live `rule_config` doesn't currently have `targeted_tract_corroboration_note` set, so its caveat message is correct but missing the "two independent documents" detail until a small migration adds it. Deferred by choice this session — cosmetic, not a correctness issue.

---

## Migration: reinstating `targeted_lookup_table` for FL Assist / FL HLP

First attempt (`homeaccessiq-migration-fl-assist-hlp-reinstate-targeted-lookup-key.sql`) matched 0 rows — it searched for `programs.name = 'FL Assist'` / `'FL HLP'`, but the real stored values (confirmed via live query this session) are:
- `Florida Assist (FL Assist)`
- `Florida Homeownership Loan Program (FL HLP)`

This is a real instance of the "wrong caveat is worse than no caveat" principle's cousin: a migration that silently affects 0 rows is worse than one that errors, because nothing on screen tells you it didn't work. `UPDATE` statements without a `RETURNING` clause report "Success. No rows returned" regardless of whether they touched 0 rows or 10,000 — that message is not evidence of success and shouldn't be read as one. **Worth carrying forward as a standing habit: always follow a bare `UPDATE` migration with a `SELECT` sanity check, and run it as its own statement — don't just glance at the "Success" message.**

Corrected migration (`homeaccessiq-migration-fl-assist-hlp-reinstate-targeted-lookup-key-v2.sql`) used the real names and was confirmed via direct query to have updated all 4 target rows (2 programs × income_threshold + financial_underwriting/purchase_price_cap).

`targeted_tract_source_url` was deliberately left unset in both migration attempts — no public URL has been confirmed for the Bond Guide's targeted-tract section, same open item as `geo_lookup_values.source_url` (handoff #4, gap #6).

---

## Live retest results (Miami-Dade, FL)

Test profile: purchase address in Miami-Dade County, $95,000 household income, household size 2, $400,000 target purchase price, credit score 648, 40% DTI.

- **Florida Assist** and **Florida Homeownership Loan Program (FL HLP)** both now show, for both `income_threshold` and `financial_underwriting`: *"This county has a targeted census tract per Florida Housing's current program, but HomeAccessIQ has no tract boundary data on file for it -- verify targeted-area status directly with Florida Housing."* No "IHCDA" anywhere. Both landed correctly in "Likely matches — pending verification," per the four-bucket result logic from handoff #3/#4.
- **HFA Preferred/Advantage PLUS** still shows its pre-existing gap (no income limit found for `fl_housing_standard_income_limits`) — expected, unrelated to this fix, tracked as its own open item.
- The IHCDA-family programs (First Step, Step Down, Next Home) all failed on `geographic_scope` before reaching the targeted-tract check, since the test buyer's purchase state is FL, not IN. **This retest does not confirm IHCDA's message is still intact for a real Indiana buyer** — that was verified separately via the isolated unit test earlier in the session (Indiana buyer input → "IHCDA" message, corroboration clause included), but a live Indiana-address retest would close the loop with the same kind of end-to-end confidence the Florida retest now has. Not yet done.

---

## Known open gaps (carried forward from handoff #5, updated)

1. **HFA Preferred/Advantage PLUS income/purchase-price limits** — needs the separate Standard TBA/PLUS TBA lender guide as source. Not started. Reconfirmed present in this session's retest.
2. **Targeted-area matching for FL Assist/FL HLP — structural bug now fixed; real tract-matching still not built.** The hardcoded-caveat bug that blocked this is resolved and `targeted_lookup_table` is live again for both programs. What's still open: building actual FL targeted-census-tract matching using the tract list already extracted from the Bond Guide (handoff #3), so this becomes a real pass/fail instead of a permanent "can't confirm" caveat. Until that's built, the current behavior (always non-computing, always flagging for verification for the 17-ish targeted counties) is the safe, correct interim state.
3. **Salute Our Soldiers** — ambiguous status, needs direct confirmation with Florida Housing. No batching partner yet identified.
4. **`reference.html`** — still reflects the pre-fix state (its caveat box for FL Assist/HLP references the IHCDA-bug rollback as an open issue). Needs an update to reflect that the bug is fixed and the targeted-lookup key is live again. Still not committed to git.
5. **`stackable_with` mutual-exclusivity enforcement** — documented in data, not enforced by the matching engine. Low priority, unchanged.
6. **`source_url` for the FL Assist/HLP income/purchase-price data** — currently NULL; confirm with Florida Housing whether the Bond Guide is posted publicly and backfill if so. (Separate from `targeted_tract_source_url`, also still unset — same underlying open question, may resolve together.)
7. **Lender-update-distribution relationship with IHCDA** — parked, not urgent.
8. **Kentucky Phase 1 baseline** — not started. One Phase 3 program (UK EAHP) on file, unrelated to Phase 1 progress (handoff #5).
9. **IHCDA's `targeted_tract_corroboration_note`** — new, low-priority item this session. Code supports it; IHCDA's live `rule_config` doesn't set it yet, so the "two independent documents" detail is currently missing from its caveat message (message is still correct, just less detailed).
10. **Live Indiana-address retest of the targeted-tract fix** — new this session. The Florida side has full live-retest confidence; Indiana has only the isolated unit-test confidence. Worth a real intake run against an Indiana address in one of IHCDA's 17 targeted-tract counties to close the loop the same way.

---

## Working habits to preserve (carried forward + new this session)

- All habits from handoffs #4–#5 remain in force.
- **New: a bare `UPDATE` migration's "Success. No rows returned" message is not evidence of success.** It reports identically whether 0 rows or every row was touched. Always follow with a `SELECT` sanity check run as its own statement, and actually look at the row count before considering a migration done.
- **New: verify program/table names against a live query before writing a migration's `WHERE` clause, rather than inferring from documentation or prior handoffs.** This session's first migration attempt matched 0 rows because `programs.name` turned out to be `'Florida Assist (FL Assist)'`, not `'FL Assist'` — a reasonable inference from the docs, but wrong.
- **New: when fixing a shared/cross-cutting code path (like a function used by multiple states' rules), verify the fix from both directions** — confirm the previously-broken case is now correct (FL → "Florida Housing") AND confirm the originally-correct case is still correct after the change (IN → "IHCDA," unchanged). Fixing one without checking the other risks a regression that looks like progress.
