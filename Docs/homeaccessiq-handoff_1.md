# HomeAccessIQ — Project Handoff

**Purpose:** Down-payment-assistance / homebuyer-program matching tool for Kelvin Hart (SmartIQ Realty / Fathom Realty), part of the "SmartIQ family" alongside an existing app called AreaIQ.

**Tagline (locked):** "Uncover funding opportunities and buyer advantages for homeownership with confidence and clarity"

---

## Stack & Infrastructure

- **Frontend:** Static HTML/CSS/vanilla JS, no build step, no framework — matches the pattern of Kelvin's existing AreaIQ app
- **Backend:** Supabase project `homeaccessiq`, under the `SmartIQ Realty` organization (free tier)
- **Hosting:** GitHub Pages (decided over Vercel — no unique need for serverless functions since Supabase Edge Functions cover that if ever needed)
- **Repo:** `github.com/klhart88/homeaccessiq` — pushed and up to date as of last session
- **Local dev:** `python3 -m http.server 8000` from the project folder, then browse `http://localhost:8000/index.html`. **Never open via `file://` — ES modules break under CORS that way.**
- **Domain:** `homeaccess.smartiqrealty.com` (Cloudflare-managed DNS, same as Kelvin's other properties) — **not yet actually deployed/pointed live**, still local-only testing
- **Email:** Resend (free tier, 3,000/mo) configured as Supabase's custom SMTP provider, verified domain `mail.smartiqrealty.com`. Supabase's default sender (2 emails/hour) was replaced with this.

## Access Model (locked decision, reversed once already — don't relitigate)

- **No Cloudflare Access.** An earlier plan explored gating the whole site behind Cloudflare Access (email allow-list + PIN) — this was explicitly abandoned. Kelvin decided the tool's quality/results should be the differentiator, not exclusivity of access.
- **Supabase email OTP is the entire auth mechanism.** Anyone can enter an email, get a 6-to-8-digit code (varies — don't hardcode an assumed length in `maxlength`), and sign in. No password anywhere.
- **Important:** Supabase's default "Confirm signup" and "Magic Link" email templates only show a clickable link by default — they don't surface `{{ .Token }}` (the actual code) unless the template body is edited to include it. This was already fixed in the live Supabase project's templates (both "Confirm signup" and "Magic Link" edited to show the code).
- RLS still fully enforces the PII boundary regardless of open signup (see below).

## Database Schema (Supabase project `homeaccessiq`)

Core tables: `states`, `geo_lookup_tables`, `geo_lookup_values`, `occupation_taxonomy`, `programs`, `program_eligibility_rules`, `program_benefits`, `program_requirements`, `buyer_profiles`, `agent_accounts`, `lead_captures`.

**PII boundary (locked):** `buyer_profiles` (income, occupation, veteran/disability status, addresses) lives only in Supabase, RLS-scoped to `auth.uid() = user_id`. Never touches EmailJS. Only `lead_captures` (contact-only: name/email/phone/notes) uses EmailJS, and only after the buyer explicitly requests follow-up.

**Agent visibility (locked):** Kelvin is the sole row in `agent_accounts` (built as a table, not a hardcoded ID, so it can extend to multiple agents later). Agent visibility into `buyer_profiles` is scoped to buyers who have an associated `lead_captures` row — using the matching tool alone does **not** expose a buyer to the agent. This is enforced via RLS policy, not app logic.

**Known RLS gotcha already fixed:** `geo_lookup_tables` was originally missing a public-read policy (everything else had one) — this caused silent, no-error empty results for every geo lookup until fixed. Already patched.

**Known Postgres gotcha to remember for future large data loads:** big `UNION ALL` blocks of literal `SELECT` statements need explicit type casts (e.g. `'2025-04-21'::date`, `null::integer`) — Postgres can't reliably infer types across many unioned branches the way it does for a single INSERT.

## Repo Structure

```
homeaccessiq/
├── index.html          — real marketing landing page, "Get Started" → intake.html
├── intake.html          — the actual buyer flow (email → code → profile form → results → follow-up)
├── css/{styles,intake,landing}.css
├── js/
│   ├── config.js              — Supabase URL/anon key + Census/EmailJS creds (Kelvin has real values filled in locally)
│   ├── supabaseClient.js
│   ├── stateRegistry.js       — queries `states` table instead of hardcoding per-state checks
│   ├── geocode.js, census-block.js, cache.js  — reused near-verbatim from AreaIQ
│   ├── matchingEngine.js      — the core eligibility evaluator (see below)
│   ├── leadCapture.js
│   ├── intakeForm.js          — auth/profile/match orchestration logic
│   └── intake-controller.js   — DOM wiring for intake.html
└── data/README.md      — explains why static per-state JSON files aren't used (DB-driven instead)
```

`.gitignore` excludes backup files, zips, and known throwaway diagnostic file patterns (`test-match.html`, `verify-*.sql`, etc.) — this repo has been through several rounds of accidental clutter and cleanup, the gitignore now prevents recurrence.

## Matching Engine — Design & Known Fixes

Client-side JS evaluation (not a Postgres function) — deliberate choice given small program counts; revisit only if it becomes a real bottleneck.

**Six rule types:** `income_threshold`, `geographic_scope`, `occupation_membership`, `buyer_status`, `employer_criteria`, `financial_underwriting`.

**Real bugs found and fixed this project (all via actual testing, not by inspection):**
1. Geo lookups need fallback logic — a flat/statewide value (`county_fips IS NULL`) or a size-agnostic value (`household_size IS NULL`) must be matched via a JS filter/fallback, not a SQL `.eq()`, since NULL never equals anything in SQL.
2. **Household size is now bracket/threshold-matched, not exact-matched** — some sources (Miami-Dade) give a limit per exact size; others (IHCDA) bucket into "1-2 person" / "3+ person" thresholds. The engine picks the highest threshold the buyer's size meets or exceeds, which correctly handles both shapes of data with one code path.
3. Exemption-trigger rules (rows with `exempts_rule_id` set) must never count as independent failures — a "waives X if veteran" rule failing (buyer isn't a veteran) doesn't mean the buyer failed a "must be a veteran" requirement; it just means no exemption applies.
4. A rule that "needs more info" (missing buyer data) and a rule that's flatly "not eligible" are different messages — showing both for the same underlying cause was fixed to be mutually exclusive in the results UI.
5. `lead_captures` insert must **not** chain `.select().single()` — that asks Supabase to read back the inserted row, which requires SELECT policy visibility the buyer doesn't have (only agents can SELECT `lead_captures`). Insert-only, no read-back.
6. DTI is entered by the buyer as a whole-number percentage (e.g. "35") and converted to decimal (0.35) client-side before saving — the schema/rules use decimal, but asking a buyer to type "0.35" is bad UX.

## Programs Currently Loaded

| Program | State | Status |
|---|---|---|
| **IHCDA First Step** | IN | ✅ Fully corrected this session — see below |
| Florida Hometown Heroes | FL | Loaded, tested working |
| AHFA Step Up | AL | Loaded, tiered-benefit bug fixed |
| Miami-Dade County Homebuyer DPA | FL (county) | Loaded, tests residence-based geographic scope |
| UK Employer Assisted Housing Program (EAHP) | KY | Loaded, tests employer-identity matching |

### IHCDA — most recent major work (this session)

The program was originally loaded as **"IHCDA First Place FHA"** — this was **wrong**. Research (cross-checked against IHCDA's own primary-source PDFs, not secondary aggregators) confirmed:

- First Place ended December 31, 2023. The current active program is **First Step**.
- Corrected terms: **5% of purchase price, non-forgivable** second mortgage (not 6%, not forgivable-over-years as some secondary sources claimed).
- **Real, complete 92-county income and acquisition-limit data loaded**, sourced directly from IHCDA's own PDF (`Inc-Acq-Limits-FS-SD-NH-4-21-2025.pdf`, effective **April 21, 2025** — IHCDA's own index page did not show anything newer at time of research, despite a secondhand source claiming a "May 25, 2026" edition exists; **this discrepancy is unresolved**).
- Credit score / DTI hard-coded thresholds (640/45%, inferred from a secondary source) were **removed** — IHCDA's own program guide defers to "lender/Master Servicer standards" with no fixed published number. Better no rule than an unconfirmed one.
- **New rule added:** purchase-price/acquisition-limit check (`financial_underwriting`, field `purchase_price_cap`) — this didn't exist before at all, even though it's a real eligibility requirement.
- Tested end-to-end and confirmed working: correct program name/terms display, purchase-price rule evaluates silently (no false "needs info"), and the household-size bracket-matching fix confirmed correct (household sizes 2 and 4/5 both correctly return Marion County's same "3+" bucket figure).

**Explicitly flagged, not yet modeled (real, known gaps):**
1. **17 counties with a targeted census tract** (Allen, Clark, Delaware, Elkhart, Floyd, Grant, Hancock, Henry, Howard, Lake, Madison, **Marion** — Kelvin's home county — Marshall, Monroe, St. Joseph, Tippecanoe, Vanderburgh) — only the lower, non-targeted-tract income figure is loaded. A buyer in the actual targeted tract may qualify at a higher limit than the tool currently shows. Needs tract-level geocoding to resolve (same category of gap as UK EAHP's `designated_zone`).
2. **30 whole-county-targeted counties** (Brown, Clinton, Crawford, Daviess, Dearborn, Decatur, Fayette, Franklin, Fulton, Greene, Jackson, Jasper, Jefferson, Knox, Lawrence, Miami, Ohio, Orange, Owen, Parke, Perry, Pike, Rush, Scott, Shelby, Spencer, Vermillion, Vigo, Washington, Wayne) have correct income data loaded, but the first-time-buyer exemption for purchasing there isn't wired up yet — only the veteran exemption exists currently. IHCDA's guide states targeted-area purchases get the same first-time-buyer waiver as veterans.
3. **Kelvin emailed IHCDA's homeownership team** (`homeownership@ihcda.in.gov`) asking to confirm whether a newer table exists (the May 2026 date discrepancy) and to clarify First Place vs. First Step — **no response yet** as of last session. Also planned a follow-up phone call (`(317) 232-7777`) that hadn't happened yet either.

## Other Known Open Items (from earlier in the project, not yet revisited)

- AHFA's tiered benefit (50% AMI grant tier) — already fixed once (separate lookup table created), confirmed working.
- Retention period for `buyer_profiles` (data has a `data_retention_expires_at` column, but no actual policy/number decided yet).
- Disclaimer language (non-lending/non-advice framing) — flagged since the very first planning session, still not drafted.
- `job_tier_min` for UK EAHP and `designated_zone` geofencing — both intentionally flagged as `needsVerification` rather than blocking, since neither can be properly evaluated without infrastructure this project doesn't have yet (a specific employer job-tier field, and tract/zone-level geocoding respectively).

## Working Habits Established This Project (worth preserving)

- **Always confirm which file actually changed before assuming a fix landed** — this project hit the "did you actually replace the file" issue multiple times; a `grep` check on the specific new code is the fast way to verify.
- **When something fails after a "should work" fix, get hard evidence (console logs, DB queries) before guessing again** — guessing wrong twice on the OTP template issue is what led to this habit.
- **Never guess data that could make the tool falsely permissive** — when uncertain, the safe default is "flag as needs verification" or "use the more conservative/lower figure," never invent a number that could tell a buyer they qualify when they might not.
- Real primary sources (agency PDFs) over secondary/aggregator summaries whenever a hard number matters — this project had multiple instances of secondary sources actively disagreeing with each other and with the primary source.

## Suggested Next Steps (pick up here)

1. Wait for/follow up on the IHCDA email response (First Place vs. First Step confirmation, May 2026 table question).
2. Consider adding the whole-county-targeted-area first-time-buyer exemption (gap #2 above) — straightforward given the existing veteran-exemption pattern.
3. Continue data curation for other states/programs, or deepen Indiana coverage further.
4. Eventually: retention policy, disclaimer language, and a real production deploy (domain currently unused, still local-testing only).
