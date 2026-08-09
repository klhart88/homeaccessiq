# HomeAccessIQ — Project Handoff #3
**Supersedes:** `Docs/homeaccessiq-handoff_2.md` (kept for history; this doc reflects current state as of 2026-07-31, end of day). Read this one first.

**Purpose:** Down-payment-assistance / homebuyer-program matching tool for Kelvin Hart (SmartIQ Realty / Fathom Realty). **Tagline (locked):** "Uncover funding opportunities and buyer advantages for homeownership with confidence and clarity"

---

## Status since handoff #2 — the big picture

Handoff #2 closed with Step Down/Next Home built but unverified, and a general "Indiana curation" gap open. Both are now fully resolved, and this session expanded well beyond Indiana:

1. **Step Down / Next Home**: tested, verified, committed.
2. **IHCDA data validation**: a live call with IHCDA confirmed every open question — program list, whole-county list, tract list, retired programs (MCC, H2O, IHS, First Place). Nothing further needed on Indiana data currency.
3. **Two real bugs found and fixed** via testing (see below).
4. **UK EAHP fully resolved**: UK HR (Azetta Beatty) confirmed directly that the 2013 scanned map is the current and only boundary — no digital version exists. Permanent limitation, not pending.
5. **A personal reference page was built** (`reference.html`) — searchable/filterable quick reference of all loaded programs, for Kelvin's own use (not part of client-facing app).
6. **Florida program curation expanded significantly** — from 2 programs to 5, with one still-open data gap (see "Immediate next step" below).

---

## Two real bugs found and fixed this session (both committed: `876f5d8`)

### 1. AHFA Step Up + Miami-Dade DPA data gaps
- **AHFA Step Up**: prior data was stale ($130,600 income limit vs. actual current $172,800) and paired with a **fabricated** second income tier (`ahfa_step_up_income_limit_50pct` = exactly half the other value, sourced from a secondary aggregator, not AHFA). Removed the fabricated tier entirely — dropped both tiered-grant `program_benefits` rows, the eligibility rule referencing the fake table, and the table itself. Updated to the real flat $172,800 limit and flat 4%/$10,000 benefit, matching AHFA's own current site exactly.
- **Miami-Dade DPA**: income limit table was completely empty (had been since original build), causing every test to show "no income limit found." Populated household sizes 1–4 with verified figures from Miami-Dade's own program page ($95,620/$109,200/$122,920/$136,500). **Household size 5+ remains unverified** — contact Shawn Topps, (786) 469-2209, if a real 5+ person case comes up.

### 2. Step Down / Next Home state-scope bug
- Discovered via a Florida test address: Step Down and Next Home were missing the base `geographic_scope` (state: IN) rule that First Step has. It wasn't copied over when Step Down/Next Home were cloned from First Step's rule rows. Result: out-of-state purchases incorrectly showed as "Likely matches — pending verification" instead of being blocked, unlike First Step.
- Fixed by adding the same state-scope rule to both programs (evaluation_order -10, runs before everything else). Verified via re-test: Florida address now correctly blocks all three IHCDA programs on state scope.

---

## IHCDA — fully confirmed via live call with IHCDA (7/31/26)

Kelvin called IHCDA directly. Every open question from handoff #2 was resolved:

- **First Step, Step Down, Next Home, Next Step confirmed as the complete, current program list** — nothing else active.
- **First Place**: confirmed fully retired (ended 12/31/2023), only relevant for existing Next Step refinances.
- **Mortgage Credit Certificate (MCC)**: confirmed no longer offered.
- **"Helping to Own" (H2O) and "IHS"**: both confirmed retired.
- **30-county whole-county-targeted list**: confirmed accurate as currently loaded (matches Feb 2026 Universal Program Guide Appendix B).
- **Targeted census tract list**: the `CENSUS-TRACTS-FOR-TARGETED-AREAS_4_16_24.pdf` (4/16/24) document is confirmed as the authoritative version.
- **Future currency confirmation**: no dedicated contact/publication cadence exists — IHCDA said the website is believed kept current, and suggested working with area lenders for direct updates (this was **not** pursued further at Kelvin's choice — parked as a future option, not urgent).
- **Additional detail learned**: none of IHCDA's loans are forgivable; a sold home's assistance is repaid via silent lien; the lien lives for the life of the mortgage; equity can be used to repay on sale. This matches how First Step/Step Down/Next Home are already modeled — no changes needed, just confirmation.

**No further Indiana/IHCDA data-validation work is needed.** This thread is closed.

---

## UK EAHP — fully resolved

Emailed Azetta Beatty (UK Employee Benefits Office) directly. Her reply (7/31/26, 12:39 PM): the posted 2013 map is still the current boundary map, and the only one UK has. **This is now a permanent, documented limitation** — not a pending item. No further outreach needed unless UK publishes something new in the future. The app's existing "verify manually" caveat is the correct, final behavior here.

---

## Florida program curation — expanded from 2 to 5 programs

Started because only Hometown Heroes + Miami-Dade County were loaded, while Florida Housing Finance Corporation (FHFC) runs a broader statewide family. Initial research used web search (secondary aggregators, often conflicting with each other), then Kelvin did a **full site crawl of floridahousing.org** (uploaded as zip files of markdown-converted pages) which resolved most open questions directly from the primary source.

### Confirmed and built (migration committed, file: `homeaccessiq-migration-fl-assist-hlp-hfa-preferred.sql` + follow-up `homeaccessiq-migration-fl-assist-hlp-preferred-income-caveat.sql`):

1. **Florida Assist (FL Assist)** — $10,000 flat, 0%, non-forgivable, deferred second mortgage.
2. **Florida Homeownership Loan Program (FL HLP)** — **$12,500**, 3% interest, fully amortizing, **30-year term** (real monthly payment ~$69/mo). Note: nearly every secondary source claimed $10,000/15-year — the real current figure per Florida Housing's own site is $12,500/30-year. This was a genuine correction, same pattern as the AHFA fix.
3. **HFA Preferred/Advantage PLUS Second Mortgage** — 3%/4%/5% of loan amount, forgivable at 20%/year over 5 years. Only pairs with HFA Preferred/Advantage conventional first mortgages (not FHA/VA/USDA).

All three: state scope (FL), first-time-buyer requirement, and (as of the follow-up migration) a **visible "pending verification" caveat** for income/purchase-price limits rather than a silent unconditional match (see "Immediate next step" below for why).

**Important structural note**: FL Assist / FL HLP / HFA Preferred/Advantage PLUS are **mutually exclusive** — a buyer picks exactly one, confirmed directly on Florida Housing's own site ("not available as stand-alone," "not available with FL Assist or FL HLP Second Mortgages"). The `stackable_with` column (uuid array) is used to reflect "not stackable" by leaving it empty, consistent with how Hometown Heroes is already stored. **The matching engine does not currently enforce this mutual exclusivity** — all three will show as independent results if all pass. This is documented but not built; a future enhancement could group them as alternatives in the results UI.

**New `program_type` values introduced**: `amortizing_loan` (FL HLP) and `forgivable_loan` (HFA Preferred/Advantage PLUS). Worth checking whether `intake-controller.js`/`intake.css` have any badge logic keyed to known `program_type` values (like Step Down's blue "rate discount" badge) — these two will render with no special badge unless one is added later.

### Confirmed retired/closed, correctly NOT built:
- **Mortgage Credit Certificate (MCC)** — Florida Housing's own FAQ page confirms it hasn't been issued since 12/31/2020.
- **Hardest Hit Fund** (all sub-programs: UMAP, MLRP, HHF-DPA, ELMORE, Principal Reduction) — confirmed fully closed, years ago.

### Flagged as ambiguous, correctly NOT built:
- **Salute Our Soldiers Military Loan Program** — still listed as an active "Special Program" on Florida Housing's current homebuyer overview page, but its own page returns a 404 "has been relocated" error on their own site. Could be a live program with a stale internal link, or something not fully retired. **Recommend confirming directly with Florida Housing (850-488-4197) before building.** If real: rate-only benefit (no DPA of its own), similar in shape to IHCDA Step Down, and per secondary sources can pair with *any* of the three DPA programs above (unlike them, not mutually exclusive with anything).

### Bonus fix:
- Hometown Heroes' `source_url` was pointing to a secondary aggregator (makefloridayourhome.com). Corrected to Florida Housing's own page (`floridahousing.org/live-local-act/hometown-heroes-program`).

---

## ⚠️ IMMEDIATE NEXT STEP — Florida income/purchase-price limits (open gap)

**What's blocking it:** FL Assist, FL HLP, and HFA Preferred/Advantage PLUS need county-level income and purchase-price limits to produce a real pass/fail (currently showing an honest "pending verification" caveat instead of a guess). Unlike Hometown Heroes, there is **no static PDF** with these figures — the authoritative source is Florida Housing's own interactive tool:

`apps.floridahousing.org/StandAlone/FTHBWizard`

**As of 7/31/26, this tool is broken** — returns a server-side ASP.NET `InvalidOperationException` (view not found), not a "moved" 404. This is a real outage on Florida Housing's end, not a navigation issue.

**Two documents were checked and rejected as the wrong source** (uploaded by Kelvin near end of session): a HUD "FY2026 Adjusted HOME Income Limits" PDF and an "income-and-rent-limits" Excel file. **These are HUD HOME Program income limits** (used for HOME/SHIP-funded programs), which use a different methodology (30%/50%/60%/80% AMI tiers) than the **bond-compliance income limits** (IRS Section 143, typically 100%/115%/140% AMI depending on family size/targeted status) that actually govern FL Assist/FL HLP/HFA Preferred, since those pair with tax-exempt mortgage revenue bond first mortgages. Loading HOME limits as a stand-in would likely **understate** the true bond-program limit — i.e., it would incorrectly tell some real buyers they don't qualify. **Do not load HOME/SHIP income limit data for these three programs** — it's the wrong framework, confirmed as a real methodological mismatch, not just a formatting difference.

**Kelvin found two more documents right at session end and was about to upload them when the conversation hit a length limit.** Those documents have NOT yet been checked — that's the very next thing to do next session.

**Recommended next actions:**
1. Check whatever two documents Kelvin uploads at the start of next session — confirm whether they're actually Bond/TBA-program-specific limits (look for language like "Section 143," "Standard Bond," "TBA," "PLUS," or explicit household-size tiers at "2 or fewer / 3 or more" rather than the 8-person HUD HOME table shape) before treating them as authoritative.
2. If they check out: populate `fl_housing_standard_income_limits` and `fl_housing_standard_purchase_price_limits` (already registered, currently empty — see migration `homeaccessiq-migration-fl-assist-hlp-preferred-income-caveat.sql` for the schema/structure already in place).
3. If they don't check out: retry `apps.floridahousing.org/StandAlone/FTHBWizard` (may be back up by then), or call Florida Housing directly (850-488-4197) for the current Bond/TBA limit table.
4. Once populated, re-test a Florida address profile — FL Assist/FL HLP/HFA Preferred should move from "pending verification" to a real computed pass/fail.

---

## Reference page (`reference.html`) — built this session, not yet updated for Florida expansion

A personal, searchable quick-reference page for Kelvin's own use (not part of the client-facing app) — built as a single static HTML file, no build step, matching the site's stack.

**Features:**
- Left sidebar nav grouped by state (IN/FL/AL/KY), with color-coded state pills.
- **Incremental search** — filters sidebar links, the at-a-glance table, and main content cards simultaneously as you type.
- **State filter chips** — default to showing all states; clicking a chip narrows to just that state (multiple can be selected together); deselecting all returns to showing everything.
- Each program card: Purpose / Key Features / Ideal Borrower, a "verified against ___, [date]" stamp, and a source link.
- At-a-glance comparison table at the top.

**Content currently covers**: IHCDA's 4 programs, Florida Hometown Heroes, Miami-Dade DPA, AHFA Step Up, UK EAHP (8 programs total) — reflecting all data corrections from this session (AHFA's flat structure, Miami-Dade's real income limits, etc.).

**NOT yet added**: the 3 new Florida programs (FL Assist, FL HLP, HFA Preferred/Advantage PLUS) or the Salute Our Soldiers ambiguity note. This is a straightforward addition once picked back up — same card format, add to the FL state group, update the at-a-glance table.

**Not yet committed to git** — exists only as a shared file from this session. Recommend saving it into the repo (unlinked from nav, per earlier discussion) and committing.

---

## Known open gaps (carried forward + updated)

1. **Florida income/purchase-price limits for FL Assist/HLP/HFA Preferred** — see "Immediate next step" above. This is the real priority.
2. **Salute Our Soldiers** — ambiguous status, needs direct confirmation with Florida Housing before building.
3. **Reference page** — needs the 3 new Florida programs added, and needs to be committed to git.
4. **AHFA Step Up's `program_benefits`/description text** was checked and found already correct (single flat benefit row, no leftover "income-tiered closing-cost grant" language) — no action needed, just noting it was verified, not assumed.
5. **`stackable_with` mutual-exclusivity enforcement** — the FL Assist/FL HLP/HFA Preferred "pick exactly one" relationship is documented in the data but not enforced by the matching engine. Low priority; worth considering if results ever show all three as simultaneous "matches" in a confusing way.
6. **Lender-update-distribution relationship with IHCDA** — mentioned as a future option during the IHCDA call (they push updates directly to area lenders), deliberately not pursued yet. Parked, not urgent.
7. **UK EAHP `designated_zone` geofencing** — **no longer an open gap in the traditional sense.** Confirmed permanent limitation (no digital boundary exists). Do not revisit unless UK publishes something new.

---

## Working habits to preserve (carried forward + new this session)

- **A full site crawl (zip of markdown-converted pages) is far more reliable than search-snippet scraping** for primary-source verification — this resolved the entire Florida program family cleanly in one pass, including catching a real error (FL HLP's true $12,500/30yr figure vs. the commonly-repeated wrong $10,000/15yr) and a genuine ambiguity (Salute Our Soldiers' 404). When a site blocks automated fetches, this is the right fallback to ask for.
- **Distinguish federal income-limit frameworks carefully** — HUD HOME/Section 8 limits and IRS Section 143 bond-compliance limits are NOT interchangeable, even though both ultimately derive from HUD AMI data. This was a real, substantive catch this session, not a formatting nitpick — loading the wrong framework would have produced confidently wrong pass/fail results.
- **A "no rule at all" gap is worse than a visible "pending verification" caveat** — the Florida income-limit follow-up migration exists specifically to convert a silent unconditional-match gap into an honest, visible one, mirroring the Miami-Dade pattern. Always prefer the visible caveat when data isn't ready.
- Every `.sql` file still needs to be manually downloaded and moved into `HomeAccess SQL Command/` before running in Supabase — this discipline held up well this session with no repeat confusion.
- Idempotent migrations (`where not exists` guards) continue to pay off — every migration this session was safe to re-run.
