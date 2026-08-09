# HomeAccessIQ — Eligibility Rule Shape (v0.1)

**Status:** Draft for review — grounded in 5 real programs, not assumptions.
**Purpose:** Answer one question before building the matching engine: what shape do eligibility rules actually need to be?

---

## Source programs used

| # | Program | Category | Why it's a good test case |
|---|---|---|---|
| 1 | AHFA Step Up closing-cost grant (AL) | State HFA grant | Tiered by AMI %, simple structured filter |
| 2 | Florida Hometown Heroes | Occupation-based state program | Long occupation list, dual income-measurement methods, exemptions |
| 3 | Miami-Dade Surtax Program | County program | Purchase price cap + income cap combo |
| 4 | University of Kentucky EAHP | Employer-assisted housing | Compound employer + tenure + geographic-zone rule |
| 5 | Florida Assist | State grant | Simple first-time-buyer + county income table |

**Finding: none of these required free text or an LLM interpretation step.** Every criterion reduces to one of six structured rule types below. That resolves the open question from the original plan — deterministic filtering is sufficient for v1.

---

## The six rule types

Every program's eligibility criteria decompose into these. A program has one or more rows in `program_eligibility_rules`, each tagged with a `rule_type`. Matching = evaluate all rows for a program against a buyer profile; all must pass (AND), unless a row has an `exemption` that waives it.

### 1. `income_threshold`
Not a flat number — almost always a **lookup by geography** (and sometimes household size).

```
rule_type: income_threshold
ami_percent: 140          -- e.g. "must not exceed 140% of AMI"
comparator: lte
income_basis: household | borrower_only   -- Hometown Heroes offers BOTH; buyer qualifies via whichever passes
geo_scope: county
geo_lookup_table: fl_hometown_heroes_county_limits   -- reference to a table, not a hardcoded value
```
*Why not a single number:* AHFA's grant tiers (50% AMI → 1% grant, 80% AMI → 0.5% grant) show a program can have **more than one income row with different outcomes attached**, not just a pass/fail cutoff. That means income rules need to link to `program_benefits`, not just gate eligibility.

### 2. `geographic_scope`
```
rule_type: geographic_scope
scope_level: state | county | city | designated_zone
allowed_values: [FL] | [Miami-Dade] | [designated neighborhoods list — UK EAHP]
```
UK's EAHP shows this can be a **custom polygon/zone list**, not just administrative boundaries — worth a `zone_reference` field pointing to a geofence table rather than assuming county-level is always granular enough.

### 3. `occupation_membership`
```
rule_type: occupation_membership
taxonomy_ref: hometown_heroes_occupations_v2026   -- maintained list, not hardcoded enum
match_mode: any_of
exemption_tags: [veteran, active_duty]    -- exempts the FIRST-TIME-BUYER rule, not this one — see below
```
The occupation list itself needs to be a **maintained, versioned taxonomy** (50+ entries, changes periodically) — a join table (`program_occupation_tags`), not an enum baked into the schema.

### 4. `buyer_status` (first-time-buyer, veteran, etc.)
```
rule_type: buyer_status
status_required: first_time_buyer
lookback_years: 3
exempts_if: [occupation_tag = veteran, occupation_tag = active_duty]
```
This is the key structural insight: **exemptions are modifiers on a rule, referencing another rule's output** (occupation), not standalone rules. The rule engine needs to evaluate in dependency order — occupation before buyer_status — not as flat independent filters.

### 5. `employer_criteria`
```
rule_type: employer_criteria
employer_location_required: same_state
min_hours_per_week: 35
min_tenure_days: 90
job_tier_min: grade_46_or_below   -- UK-specific, program-defined enum
```
Compound by nature — needs multiple sub-fields in one row rather than forcing it into generic income/occupation shapes.

### 6. `financial_underwriting`
```
rule_type: financial_underwriting
field: credit_score | dti_ratio | purchase_price_cap
comparator: gte | lte
value: 640
geo_lookup_table: <optional, purchase price caps vary by county>
```

---

## Explicitly NOT eligibility rules — separate table

Homebuyer education course completion, "must use an approved/participating lender," proof-of-employment-at-closing — these gate **closing**, not **matching**. Mixing them into `program_eligibility_rules` would pollute matching queries with non-filtering rows.

Recommendation: a separate `program_requirements` table (`requirement_type`: education_course | approved_lender_only | proof_document), surfaced in the UI as "you qualify, and here's what you'll need to do" — not blended into the match filter logic.

---

## Metadata every program needs regardless of rule type

- `last_verified_date` — surfaced to the user, not just internal
- `funding_status`: open | first_come_first_served | exhausted | seasonal — Hometown Heroes and Texas's program both run out of funds mid-year; this is a live field, not a one-time entry
- `stackable_with`: array of program IDs — several sources note buyers combine a state grant with a county/city program; worth capturing now even if v1 doesn't build a stacking calculator, since retrofitting it later means re-touching every program row

---

## What this settles vs. what's still open

**Settled:** Rule representation is deterministic/structured. No LLM matching step needed for v1. Six rule types cover all five real programs tested.

**Still open (flagged, not solved here):**
- Who owns/updates the occupation taxonomy and geo lookup tables as they change
- Whether `stackable_with` is in scope for v1 or a v2 flag only
- The `program_requirements` / closing-gate table wasn't in the original schema sketch at all — worth confirming this doesn't get built as an afterthought
