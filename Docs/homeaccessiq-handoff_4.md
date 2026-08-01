# HomeAccessIQ — Project Handoff #4
**Supersedes:** `Docs/homeaccessiq-handoff_3.md` (kept for history; this doc reflects current state as of 2026-07-31, late night). Read this one first.

**Purpose:** Down-payment-assistance / homebuyer-program matching tool for Kelvin Hart (SmartIQ Realty / Fathom Realty). **Tagline (locked):** "Uncover funding opportunities and buyer advantages for homeownership with confidence and clarity"

---

## Status since handoff #3 — the big picture

Handoff #3 closed with Florida program curation at 5 programs but one real open gap: FL Assist, FL HLP, and HFA Preferred/Advantage PLUS had no income/purchase-price limit data, showing an honest "pending verification" caveat instead. This session closed most of that gap, found and fixed a real bug along the way, and caught up `reference.html` on the Florida expansion:

1. **FL Assist and FL HLP income/purchase-price limits: populated and verified live.** All 67 FL counties, sourced directly from Florida Housing's own Standard Bond Guide (a lender-facing PDF Kelvin obtained directly, not a secondary aggregator).
2. **A real bug found and fixed**: an incorrect IHCDA-referencing caveat surfaced on Florida results, tracked to its root cause, and hotfixed same-session.
3. **HFA Preferred/Advantage PLUS remains unresolved** — confirmed this Bond Guide simply doesn't cover it (it's a TBA-only product; no "PLUS BOND" exists). Needs a different source document.
4. **`reference.html` updated** with the three new Florida programs plus a Salute Our Soldiers entry — still not committed to git.

---

## FL Assist / FL HLP income & purchase-price limits — populated and verified

**Source:** Florida Housing Standard Bond Guide 6.25.26 (Lakeview) — a lender-facing PDF Kelvin uploaded directly (not a public URL; see "source_url" note below). Explicitly confirmed as the correct IRS §143 bond-compliance framework (not the HUD HOME framework flagged as wrong in handoff #3) via its own household-size bracket shape ("NonTargeted 1-2 Person / 3+ Person," not the 8-person HUD HOME table shape) and its own reference to §143(m) recapture tax.

**Schema discovery this session:** the app's income/purchase-price data model is generic, not per-program tables. A registry table (`geo_lookup_tables`: table_name/description/value_type) points to a shared values table (`geo_lookup_values`: lookup_table_id, state_code, county_fips, household_size, numeric_value, effective_date, source_url, last_verified_date). Programs reference a lookup table by name via a `lookup_table` key inside `program_eligibility_rules.rule_config` (JSONB). IHCDA's existing `ihcda_first_step_income_limits` was used as the reference pattern: `household_size` is used as a literal bracket stand-in (2 = "1-2 person," 3 = "3+ person"), not a true per-size row for every household size.

**Real finding — FL Assist and FL HLP are NOT interchangeable tables:** direct row-by-row comparison of the Bond Guide's two income tables showed FL HLP's "NonTargeted 3+ Person" figures differ from FL Assist's in **9 counties**: Baker, Collier, Gulf, Martin, Monroe, Okaloosa, Polk, St. Lucie, Walton (e.g., Collier: FL Assist $145,200 vs. FL HLP $169,310). Purchase price limits, by contrast, were verified identical between the two programs' own tables and are shared. This is why the final structure uses **six separate lookup tables**, not the one originally assumed:

- `fl_assist_income_limits_nontargeted`
- `fl_assist_income_limits_targeted`
- `fl_hlp_income_limits_nontargeted`
- `fl_hlp_income_limits_targeted`
- `fl_housing_purchase_price_limits_nontargeted` (shared by both programs)
- `fl_housing_purchase_price_limits_targeted` (shared by both programs)

All 67 counties populated in each, effective with reservation 05/06/2026. `source_url` was left NULL with a note in the migration header — no public URL was confirmed for this specific guide PDF; it was provided directly by Kelvin. **Follow-up: confirm with Florida Housing whether this guide is posted publicly and backfill `source_url` if so.**

**Migration file:** `homeaccessiq-migration-fl-assist-hlp-income-purchase-price-data.sql` — run successfully, saved to repo (`HomeAccess SQL Command/`) at 9:12 PM EST.

**One thing not yet confirmed:** the purchase-price inserts use `household_size = NULL` (purchase price doesn't vary by household size, unlike income). This ran successfully, meaning the column allows NULL — but worth keeping in mind if a future migration assumes `household_size` is always non-null.

---

## Real bug found and fixed: incorrect IHCDA caveat on Florida results

**What happened:** after the income/purchase-price migration ran, FL Assist and FL HLP retested successfully at the data level (no more "no income limit found") but surfaced a new, wrong caveat instead of a real pass/fail:

> "This county has a targeted census tract per **IHCDA's** current program, but HomeAccessIQ has no tract boundary data on file for it — verify targeted-area status directly with **IHCDA**."

This is nonsensical for a Florida property — IHCDA is Indiana's housing finance agency.

**Root cause (inferred, not yet confirmed in source):** the original migration added a `targeted_lookup_table` key to FL Assist's and FL HLP's `rule_config`, intended to prepare the data for a future targeted-area check. HFA Preferred/Advantage PLUS — whose `rule_config` was deliberately not touched — continued showing its old, unrelated placeholder message, which isolates the trigger to that key specifically. This strongly suggests the matching engine has a shared "check targeted census tract" code path, originally built for IHCDA, with **"IHCDA" hardcoded into the caveat message** rather than parameterized by state/program. Adding the key made FL Assist/HLP walk into that code path for the first time, surfacing Indiana-specific wording on a Florida result.

**Fix applied:** a hotfix migration (`homeaccessiq-migration-fl-assist-hlp-remove-targeted-lookup-key-hotfix.sql`) stripped the `targeted_lookup_table` key back out of both programs' `rule_config`, reverting them to checking only the nontargeted lookup tables. Run successfully; retested clean — FL Assist and FL HLP now show real ✓ matches with no caveat at all when the numbers support it (verified against a real Miami-Dade test case: $95,000 household income, household size 2, against Miami-Dade's $136,200 nontargeted limit and $697,889 nontargeted purchase-price cap — both pass correctly).

**This is a real, not cosmetic, finding — carried forward as an open gap** (see below): the targeted-area lookup tables are fully populated and sitting ready, but nothing in the app reads them yet, and the underlying caveat-message bug hasn't been fixed at the code level, just avoided by not triggering it.

---

## HFA Preferred/Advantage PLUS Second Mortgage — still fully open

Untouched by both migrations this session, by design. Confirmed (via the eHousingPlus rate page) that PLUS is a **TBA-only product** — there is no "PLUS BOND" offering, only "PLUS TBA." The Standard Bond Guide used for FL Assist/FL HLP doesn't cover it at all; it needs the separate **Standard TBA / PLUS TBA lender guide** as its own source document before any income/purchase-price data can be populated. Still shows the old "pending verification" placeholder caveat in the live app — accurately, since no real data exists for it yet.

---

## `reference.html` — caught up on the Florida expansion (still not committed)

Added, matching the existing card format exactly (sidebar link → glance-table row → full card with Purpose/Key Features/Ideal Borrower/verified-stamp/source-line):

- **FL Assist** and **FL HLP** — verified-stamps reflect that income/purchase-price data is now live; each carries a caveat box explaining the targeted-area gap (data populated, not yet wired in) and referencing the IHCDA-bug rollback for context.
- **FL HLP's card specifically calls out** the 9-county NonTargeted-3+-person divergence from FL Assist as a named, real finding — not buried in a footnote.
- **HFA Preferred/Advantage PLUS** — tagged with a "PLUS TBA only" badge; caveat box explains it needs a different source document than the Bond Guide.
- **Salute Our Soldiers** — added with deliberately distinct visual treatment (dimmed card opacity, amber "Status unconfirmed" badge, new `.unconfirmed-status`/`.badge.unconfirmed` CSS) since this isn't a data caveat on a working program — the program's very existence is unconfirmed. Carries the same call-Florida-Housing-first recommendation as handoff #3.

**Still not committed to git** — same state as handoff #3 flagged. Recommend committing now that it reflects current reality.

---

## Known open gaps (carried forward + updated)

1. **HFA Preferred/Advantage PLUS income/purchase-price limits** — needs the separate Standard TBA/PLUS TBA lender guide as source. Not started.
2. **Targeted-area matching for FL Assist/FL HLP** — the four targeted-variant lookup tables (`fl_assist_income_limits_targeted`, `fl_hlp_income_limits_targeted`, plus the shared targeted purchase-price table) are fully populated and ready, but nothing in the matching engine reads them. Two things need to happen before `targeted_lookup_table` can safely go back into `rule_config`:
   - Find and read the matching-engine code (likely `intake-controller.js`) for the function producing the IHCDA-tract-boundary caveat; confirm whether the message is hardcoded to "IHCDA" or templated, and generalize it to the correct state/agency per program.
   - Build real FL targeted-census-tract matching using the tract list already extracted from the Bond Guide's "FEDERALLY DESIGNATED TARGETED AREAS" section (all 67 counties' tract codes, already in hand from handoff #3's crawl).
   - Until both land, the app's current behavior (nontargeted figures for everyone) is the safe default — it can under-serve a targeted-area buyer (showing no match when a higher limit would actually qualify them) but never wrongly denies a real buyer.
3. **Salute Our Soldiers** — ambiguous status, needs direct confirmation with Florida Housing (850-488-4197) before building. Unchanged from handoff #3.
4. **`reference.html`** — updated with Florida expansion this session; still needs to be committed to git.
5. **`stackable_with` mutual-exclusivity enforcement** — FL Assist/FL HLP/HFA Preferred PLUS "pick exactly one" relationship is documented in data but not enforced by the matching engine. Low priority, unchanged from handoff #3.
6. **`source_url` for the FL Assist/HLP income/purchase-price data** — currently NULL; no public URL confirmed for the Bond Guide PDF used this session. Confirm with Florida Housing whether it's posted publicly and backfill if so.
7. **Lender-update-distribution relationship with IHCDA** — parked, not urgent. Unchanged from handoff #3.
8. **UK EAHP `designated_zone` geofencing** — permanent limitation, confirmed handoff #3. No change.

---

## Working habits to preserve (carried forward + new this session)

- **Cross-checking two source tables row-by-row before assuming they're shareable paid off directly this session** — the FL Assist/HLP NonTargeted-3+-person divergence (9 counties) would have been silently lost if the tables had been merged on the (reasonable-looking) assumption that "NonTargeted" meant the same thing in both. When two tables look identical at a glance, verify a full pass before merging or sharing infrastructure between them.
- **A design decision with real downstream consequences (how to model targeted vs. non-targeted limits, given no schema flag existed) was surfaced and decided explicitly** rather than silently picked — this is worth continuing whenever a schema gap forces an architectural choice rather than a data-entry one.
- **Test results are the fastest way to catch a real bug** — the IHCDA-caveat issue would not have been obvious from reading code or migrations in isolation; it only showed up by actually retesting a real address after the change. Continue re-testing after every rule_config or lookup-table change, not just after data-only migrations.
- **A wrong caveat is worse than an honest "pending" one** — the same principle from handoff #3 ("no rule at all is worse than a visible pending-verification caveat") extends one level further: a caveat that's actively incorrect (naming the wrong agency) is worse than either a silent gap or an honest "can't confirm yet." When in doubt, revert to the honest-gap state rather than ship a wrong-but-confident message.
- Every `.sql` file still needs to be manually downloaded and moved into `HomeAccess SQL Command/` before running in Supabase — held up again this session.
- Idempotent migrations (`where not exists` guards) continue to pay off — the hotfix migration in particular relied on this to safely target only the rows that actually had the stray key.
