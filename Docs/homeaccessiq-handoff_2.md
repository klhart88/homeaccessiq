# HomeAccessIQ — Project Handoff #2
**Supersedes:** `Docs/homeaccessiq-handoff_1.md` (kept for history; this doc reflects current state as of 2026-07-31). Read this one first; fall back to #1 only for deep background on the original build.

**Purpose:** Down-payment-assistance / homebuyer-program matching tool for Kelvin Hart (SmartIQ Realty / Fathom Realty). **Tagline (locked):** "Uncover funding opportunities and buyer advantages for homeownership with confidence and clarity"

---

## Status since handoff #1 — the big picture

Handoff #1 described the site as **local-testing only, not yet deployed**. That's no longer true: **the site is live in production** at `homeaccessiq.smartiqrealty.com` and has been confirmed working end-to-end via real browser testing on the live domain (screenshots/PDF exports from the live URL exist as proof). DNS/GitHub Pages/CNAME are all working. This was discovered mid-session, not deliberately announced — worth a quick sanity check next session that this is still true and nothing regressed.

Also resolved: the original "does a May 2026 income-limits edition exist?" question from handoff #1 — **yes**, confirmed and loaded (see below).

---

## Stack & Infrastructure (unchanged from #1 except deployment status)
- Frontend: static HTML/CSS/vanilla JS, no build step
- Backend: Supabase project `homeaccessiq`
- Hosting: GitHub Pages, **now actually live** at `homeaccessiq.smartiqrealty.com`
- Repo: `github.com/klhart88/homeaccessiq`
- Local dev: `python3 -m http.server 8000` from the project folder — **never `file://`**
- Email: Resend via Supabase SMTP (unchanged)

## Access Model (unchanged, still locked)
Supabase email OTP only, no Cloudflare gate. See handoff #1 for full detail — nothing changed here.

---

## Critical recurring workflow gotcha (learned the hard way, repeatedly, this session)

**Every time Claude shares a `.sql` migration file in chat, it must be explicitly downloaded and moved into `HomeAccess SQL Command/` before running it in Supabase.** Running it in the Supabase SQL editor does NOT save it to the repo — this caused the same "file exists in Supabase but not in git" confusion at least four separate times this session. Establish the habit: download → `mv` into the folder → *then* open in Supabase and run → `git add`/`commit`/`push` afterward. Also: Supabase's SQL editor only runs SQL — `ls`, `git`, etc. go in Terminal, not there (this tripped up a couple of times too).

Also learned: **`web_fetch`/Supabase SQL editor results get visually truncated** for wide/long values (e.g. `rule_config` JSON). Use `jsonb_pretty()` or flatten with `jsonb_each()`/one-row-per-key queries instead of trusting the raw table view.

Also learned: the Census geocoder needs a **real street address**, not a building name (e.g. "160 Patterson Office Tower" fails; "201 E Main St, Lexington, KY 40507" works). Matters for any future UK-related test addresses.

---

## Database Schema — additions since handoff #1

All in `HomeAccess SQL Command/`, run in this order (all idempotent, safe to re-run):

1. `fix-geo-lookup-tables-rls.sql`, `homeaccessiq-migration-buyer-profile-fields.sql`, `homeaccessiq-migration-unique-buyer-profile.sql` — pre-existing, from before this session, already committed and applied.
2. `homeaccessiq-migration-ihcda-targeted-county-exemption.sql` — **Gap #2 (whole-county-targeted first-time-buyer exemption)**. Adds a `geographic_scope` rule for IHCDA First Step covering the 30 whole-county-targeted counties, `exempts_rule_id` pointing at the `first_time_buyer` rule. Verified via direct `matchProgramsForBuyer()` smoke test (Wayne vs. Hamilton county, paired comparison). **Applied and committed.**
3. `homeaccessiq-migration-ihcda-targeted-tract-infrastructure.sql` — **Gap #1 (targeted-tract, not whole-county)**. Adds:
   - `buyer_profiles.purchase_census_tract` (recovers a value `geocode.js` already computed but was previously discarded)
   - `targeted_census_tracts` table (public-read RLS) — tract-membership list for the 17 tract-targeted counties, sourced from a 2020 IHCDA document at the time
   - Two new `geo_lookup_tables` entries (`ihcda_first_step_income_limits_targeted`, `ihcda_first_step_acquisition_limit_targeted`) with real elevated-tier figures for all 17 counties
   - Updated First Step's `income_threshold`/`financial_underwriting` rule_configs with `targeted_lookup_table` pointers
   - **Deliberately never computes a real pass/fail from tract data** — always returns `needsVerification`, since the tract list's currency wasn't confirmed. Hancock County intentionally NOT loaded here (zero tracts in the 2020 source — a real gap, not an oversight).
   - **Applied and committed.**
4. `homeaccessiq-migration-hancock-tract-2024-corroboration.sql` — Kelvin found a **2024** IHCDA tract document (`CENSUS-TRACTS-FOR-TARGETED-AREAS_4_16_24.pdf`) while browsing IHCDA's site directly. Compared tract-by-tract against the 2020 data: **all 16 previously-loaded counties were byte-for-byte identical across 4 years** — strong evidence the original data was correct (tract boundaries only redraw once a decade). **Hancock's real tract (4104.01) was found and added** — the one genuine gap is now filled. `targeted_tract_data_status` deliberately still NOT flipped to "confirmed" (this is strong self-sourced corroboration, not a formal IHCDA answer) — but the engine's caveat wording was updated to reflect the two-document agreement rather than "unconfirmed 2020 data." **Applied and committed.**
5. `homeaccessiq-migration-ihcda-2026-05-25-refresh.sql` — **Major finding**: Kelvin found IHCDA's actual current income/acquisition-limits document, dated **May 25, 2026** (confirms the discrepancy flagged in handoff #1). All dollar figures loaded earlier in this project (base 92-county table, both new targeted-tier tables) were built on the **2025-04-21** document, now superseded. This migration updates ALL of it **in place** (not parallel historical rows — `fetchGeoLookupValue()` doesn't filter on `effective_date`, so old+new rows side by side would be ambiguous). County classifications (`+`/`*`) did NOT change between the two documents — pure dollar-figure refresh. One manually-confirmed data point: Daviess/Decatur's 3+-person figure looked like `$33,420` in the source (missing a leading "1" relative to every other county's `$133,420` at that tier) — Kelvin confirmed against the actual PDF that `$133,420` is correct. **Applied and committed.**
6. `homeaccessiq-migration-buyer-profile-retention-policy.sql` — **Decision (Kelvin): 1 year retention after last activity, hard delete.** Trigger rolls `data_retention_expires_at` forward on every insert/update (based on activity, not fixed at signup). Daily `pg_cron` job (verified registered, job id 1, active) purges expired rows, and also wires in the pre-existing but previously-unused `deleted_at` + 30-day-grace column for a future buyer-initiated deletion flow. Confirmed safe: `lead_captures.buyer_profile_id` is `ON DELETE SET NULL`, so hard-deleting a profile never removes an agent's contact/follow-up record. **Applied and committed.**
7. `homeaccessiq-migration-uk-eahp-job-tier.sql` — Real UK EAHP job-tier logic, sourced from UK HR's own eligibility page. Fixed two real bugs: `job_tier_min` never actually existed in the rule's config (dead code, no check was running at all), and `min_tenure_days: 90` was applied unconditionally including to faculty, who are actually eligible **immediately** per UK's own policy — a live bug affecting real faculty users. Added `buyer_profiles` columns: `employer_position_type`, `employer_faculty_rank`, `employer_staff_grade`, `employer_is_hospital_position`. New `job_tier_requirement` config (faculty by rank — only instructor/assistant professor eligible; staff by MAXIMUM grade, not minimum — ≤46 general / ≤10 hospital) plus `tenure_exempt_position_types`. **Applied, committed, and verified live** via three real test profiles (staff grade 40 passed cleanly; staff grade 50 failed with the new real reason; faculty with NO start date on file passed cleanly, proving the tenure-exemption fix actually works).
8. `homeaccessiq-migration-ihcda-step-down-next-home.sql` — **NOT YET COMMITTED, TESTING INCOMPLETE.** See "Immediate next step" below — this is the most important thing to pick up.

## Database Schema — full current picture of new tables/columns
- `targeted_census_tracts` (new table): `state_code`, `county_fips`, `tract_geoid`, `source_url`, `source_last_updated`, `last_verified_date`
- `buyer_profiles` new columns: `purchase_census_tract`, `employer_position_type`, `employer_faculty_rank`, `employer_staff_grade`, `employer_is_hospital_position`, plus the pre-existing `data_retention_expires_at`/`deleted_at` now actually wired up with a trigger + scheduled purge job
- Two new `geo_lookup_tables` rows for IHCDA's targeted-tract tier (income + acquisition), all 92-county base rows refreshed to 2026-05-25 figures

---

## Matching Engine (`js/matchingEngine.js`) — all fixes since handoff #1

1. **Household-size bracket matching fixed** — was exact-match only; now treats stored `household_size` as a floor (highest bracket the buyer's size meets or exceeds), correctly handling both exact-match sources (Miami-Dade) and bucketed sources (IHCDA). Real, live bug: every single-person buyer in Indiana was previously getting a false "needs verification" regardless of actual income.
2. **`needsVerification`/`unmetReasons` mutual exclusivity** — a rule no longer double-reports as both "missing info" and "ineligible" simultaneously.
3. **`lead_captures` insert fix** — removed `.select().single()` after insert, which required SELECT-policy visibility the buyer doesn't have.
4. **Targeted-tract caveat logic** (`targetedTractCaveat()` + three query helpers) — for the 17 IHCDA tract counties, always returns `needsVerification` (never a computed pass/fail) but the message states the actual determination (tract matched / not matched / no inventory on file for that county at all — Hancock's original gap had its own distinct message before being fixed).
5. **UK EAHP job-tier logic** — see migration #7 above. Real rank/grade-based eligibility check plus faculty tenure exemption.
6. **`fetchGeoLookupValue`, `evaluateIncomeThreshold`, `evaluateFinancialUnderwriting`** are all now generic enough that **Step Down and Next Home need zero engine code changes** — they reuse the exact same functions via new `rule_config` rows only.

## Buyer Intake Flow — now fully in git (was previously local-only, a real gap discovered mid-session)
`intake.html`, `js/intakeForm.js`, `js/intake-controller.js`, `css/intake.css`, `css/landing.css` were sitting on Kelvin's laptop only, never committed, despite being core product. Now all committed. Also fixed along the way:
- `intakeForm.js` now saves `purchase_census_tract` (previously computed by `geocode.js` and silently discarded)
- First-time-buyer checkbox: relabeled for clarity ("I qualify as a first-time homebuyer (have not owned a home in the past 3 years)") and **no longer defaults to checked** — it was silently granting first-time-buyer status to anyone who didn't notice/uncheck it.

## Results page UI — now a four-tier split (was a flat match/no-match split in handoff #1)
Decisions made by Kelvin, implemented and live-tested:
1. **✓ Match** (green) — clean pass, no caveats
2. **✓ Likely matches — pending verification** (amber-green, new) — core numbers all cleared, only an external detail (e.g. tract-list currency) unconfirmed. "Pending confirmation:" wording.
3. **⚠ Other programs — insufficient information** (amber) — has real hard blockers AND unconfirmed details; explicitly de-prioritized in the copy ("unlikely to be worth pursuing unless your situation changes")
4. **No match** (grayed out)

This split exists specifically because a program with zero unmet reasons but a needsVerification caveat used to show a green checkmark like a clean match — misleading. Live-tested and confirmed working correctly across many real scenarios.

**Disclaimer footer** (Kelvin's finalized legal language, non-lending/non-advice framing) is now on both `index.html` and `intake.html` via shared `.site-footer`/`.disclaimer` CSS in `css/styles.css`. Not lawyer-reviewed by Claude — Kelvin should have brokerage compliance confirm if state/Fathom-specific language (broker license #, Equal Housing statement) is required; deliberately left out.

**Benefit-type badge** (new, for Step Down) — a blue pill badge reading "Interest rate discount — no down payment assistance," rendered whenever `result.program.program_type === 'rate_reduction'`. **Not yet confirmed working in the browser** — see below.

---

## ⚠️ IMMEDIATE NEXT STEP — Step Down / Next Home (incomplete, needs verification)

This is the very last thing worked on before this handoff was written, and **the results are unconfirmed**. Here's exactly where it stands:

**What was built:** `homeaccessiq-migration-ihcda-step-down-next-home.sql` adds two new IHCDA programs, reusing First Step's already-loaded, already-refreshed income/acquisition data (same source PDF explicitly covers "First Step, Step Down, and Next Home"):
- **Step Down**: rate-only, **no down payment assistance at all** (IHCDA's own description: "a rate-only program for qualifying first-time homebuyers"). Same first-time-buyer/veteran/whole-county-targeted-exemption structure as First Step, cloned dynamically from First Step's actual rule rows (not hardcoded/re-guessed). `program_type = 'rate_reduction'` so the UI can flag it distinctly.
- **Next Home**: 3.5% non-forgivable DPA, confirmed via IHCDA's own program guides to have **no first-time-buyer restriction at all** (available to first-time AND repeat buyers). Same income/acquisition limits as First Step, no exemption rules needed (there's no first-time-buyer rule to exempt from in the first place).

**What's confirmed:** The migration ran in Supabase and returned "Success. No rows returned" (expected for a `do $$...$$` block with no exceptions raised — this generally means it completed without hitting a `raise exception`, i.e. it found First Step's program/rules correctly and didn't error out). **Not independently re-verified with a follow-up query** (e.g. confirming `programs` now has rows for 'IHCDA Step Down' and 'IHCDA Next Home', and that their `rule_config`s look right) — do that first.

**What's NOT confirmed:**
- Kelvin ran two test profiles (first_time_buyer=false and =true, otherwise identical) locally, but the resulting screenshots were never received in this conversation — Kelvin hit Claude's max-image-count limit mid-upload. **The actual test results are unknown.**
- **Unclear whether `js/intake-controller.js` and `css/intake.css` (the benefit-type badge changes) were ever swapped into the local project folder before this test ran.** If not, Step Down would still show up in results, just without the badge — that alone isn't a failure, but worth explicitly confirming which files were actually in place during the test.
- Nothing from this migration or the badge UI changes has been committed to git yet.

**Recommended first actions next session:**
1. Run a verification query: `select name, program_type from programs where name ilike '%Step Down%' or name ilike '%Next Home%';` — confirm both exist with the right `program_type`.
2. Confirm `js/intake-controller.js` and `css/intake.css` (badge changes) are actually in place locally — `git status` will show them as modified if they were downloaded and swapped in; if `git status` shows them unmodified, they need to be applied first.
3. Re-run the same two test profiles (first_time_buyer false/true, otherwise identical, real Indiana address that already worked for First Step) and actually look at the results this time:
   - Expect: **Next Home should appear as a match/likely-match regardless of first_time_buyer value** — that's the entire point of the "no restriction" fix.
   - Expect: **Step Down should appear with the blue "Interest rate discount" badge**, and should behave like First Step re: first_time_buyer (blocked when false, unless in an exempted area).
4. Once confirmed, commit: the migration SQL, `js/intake-controller.js`, `css/intake.css` together.

---

## Known open gaps (carried forward + updated)

1. **UK EAHP `designated_zone` geofencing** — still unbuilt, deliberately. The only published boundary is a hand-drawn PDF map (`hr.uky.edu/sites/default/files/forms/benefits_eahp_map.pdf`), last revised **2013**, zero machine-readable content. Digitizing it would mean guessing coordinates off an old scanned image with no way to cross-check — the kind of fabricated-data risk this project avoids. Recommended: reach out directly to UK's EAHP contact (`azetta.beatty@uky.edu`, UK Employee Benefits Office) to ask whether a real digital boundary exists at all, same approach as the IHCDA tract-currency question below.
2. **IHCDA tract-list formal confirmation** — low priority now given the 2024 corroboration found this session, but still no direct answer from `homeownership@ihcda.in.gov` or via phone. Not urgent.
3. **Step Down / Next Home** — see "Immediate next step" above, this is the real priority.
4. **Further Indiana data curation** — open-ended. IHCDA also has a "Next Step" program, but that's a refinance-only product for existing IHCDA borrowers, not a purchase-assistance program a buyer would search for — deliberately excluded from consideration as out of scope for this tool.

## Working habits to preserve (carried forward + new this session)
- Never guess data that could make the tool falsely permissive; real primary sources over secondary aggregators, always — this caught multiple real discrepancies this session (the 2026 date, the Hancock gap, the Daviess/Decatur typo, UK's actual job-tier direction).
- Always verify a "should work" fix with hard evidence (a real query, a real smoke test) before moving on — caught the leftover "last updated 2020" text bug, the geocoding building-name failure, and confirmed the Step Down/Next Home groundwork before assuming success.
- Save every shared `.sql` file into `HomeAccess SQL Command/` immediately, before running it in Supabase — this was the single most repeated friction point this session.
- When testing multi-branch logic (like the four-tier results split or the job-tier rules), design paired/contrasting test profiles that isolate exactly one variable — this consistently produced clean, unambiguous confirmation throughout this session.
