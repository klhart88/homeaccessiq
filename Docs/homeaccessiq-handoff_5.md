# HomeAccessIQ — Project Handoff #5
**Supersedes:** `Docs/homeaccessiq-handoff_4.md` (kept for history; this doc reflects current state as of 2026-08-01). Read this one first.

**Purpose:** Down-payment-assistance / homebuyer-program matching tool for Kelvin Hart (SmartIQ Realty / Fathom Realty). **Tagline (locked):** "Uncover funding opportunities and buyer advantages for homeownership with confidence and clarity"

---

## Status since handoff #4 — the big picture

No data or code work happened this session. This handoff documents three clarifications that came out of reviewing the newly-introduced **Data Curation Strategy** document against the real state of the project, plus one factual correction to the record. **`HomeAccessIQ_Data_Curation_Strategy_v2.docx` was produced this session** to capture these clarifications formally. No SQL, migrations, or `reference.html` changes were made — those items carry forward unchanged from handoff #4 (see "Known open gaps," below).

---

## Correction: Kentucky's existing program is Phase 3 tier, not a Phase 1 start

Handoff #4 didn't mention Kentucky. Clarified this session: Kentucky research was started in an earlier session (approximately handoff #2) and currently has **one curated program — the University of Kentucky Employer Assisted Housing Program (EAHP)**.

This is an employer-assisted housing program, which the curation strategy classifies as **Phase 3**, not Phase 1. Its presence in the database does not represent Phase 1 progress for Kentucky — Kentucky's statewide HFA programs, DPA, income/purchase-price limits, targeted areas, MCC, and occupation-specific programs are all still unresearched. Treat Kentucky as a state where Phase 1 baseline research has **not started**, with one unrelated Phase 3 entry already banked.

(Earlier in this conversation this was initially misidentified as a UK-based EAHP program before the University of Kentucky correction — noting here so the record is unambiguous going forward.)

---

## Curation strategy: relationship to structural design and stability

The curation strategy document's purpose is to speed up and focus *curation* — deciding what to research next and in what order. It is explicitly **secondary to the overall functionality and stability of HomeAccessIQ**. Keeping a structural design in place that can be leveraged across all states as the platform scales is a higher priority than hitting any curation target the strategy describes.

Practical effect on current open items:

- **The targeted-area matching engine bug (hardcoded "IHCDA" caveat, handoff #4)** is a structural issue, not a curation task. It should be treated as a priority fix independent of any state's curation schedule — not queued behind data work. The strategy document's classification of "targeted areas" as a Highest-Priority *dataset* doesn't change this; the code-level fix is a design/stability matter first.
- **Schema and shared code paths** (e.g., the `lookup_table` / `targeted_lookup_table` pattern discovered this session in handoff #4) should be built so they generalize across all 50 states from the outset, even when only one or two states currently populate the relevant tables. A pattern that has to be reworked before it can serve the next state is a structural cost.
- Curation-strategy references are for sequencing curation work only. If a curation-strategy recommendation ever conflicts with structural design, the structural recommendation wins.

---

## Curation strategy: batch outreach across states rather than idling

New standing habit: when curation requires direct confirmation from an agency (e.g., "is this program still active," "which source document governs this data"), look for opportunities to batch that outreach across multiple states or programs at once, rather than pursuing one confirmation-needed item at a time and sitting idle waiting on a single response.

Currently open outreach item: **Salute Our Soldiers** (Florida Housing, 850-488-4197) — no batching partner yet identified since it's Florida-specific. As more states reach their Phase 1 pass, review open confirmation-needed items across all states before initiating outreach, and group by agency type or question type where possible.

---

## Deliverable produced this session

**`HomeAccessIQ_Data_Curation_Strategy_v2.docx`** — supersedes the original curation strategy document. Retains all Phase 1/2/3 content and the Phase 1 Data Priorities and Decision Framework sections unchanged, and adds:
1. A "Relationship to Structural Design and Stability" section (see above).
2. An "Outreach Efficiency" section (see above).
3. A clarification under "Existing Research Remains Valid" that phase-tier classification is per-program, not per-state, using the Kentucky/EAHP case as the worked example.

---

## Known open gaps (carried forward from handoff #4, unchanged)

1. **HFA Preferred/Advantage PLUS income/purchase-price limits** — needs the separate Standard TBA/PLUS TBA lender guide as source. Not started.
2. **Targeted-area matching for FL Assist/FL HLP** — lookup tables populated, matching engine doesn't read them yet. Per this handoff's structural-priority clarification, the underlying hardcoded-caveat bug fix should not wait behind curation scheduling.
3. **Salute Our Soldiers** — ambiguous status, needs direct confirmation with Florida Housing. Open outreach item; no batching partner yet.
4. **`reference.html`** — updated with Florida expansion as of handoff #4; still needs to be committed to git.
5. **`stackable_with` mutual-exclusivity enforcement** — documented in data, not enforced by the matching engine. Low priority, unchanged.
6. **`source_url` for the FL Assist/HLP income/purchase-price data** — currently NULL; confirm with Florida Housing whether the Bond Guide is posted publicly and backfill if so.
7. **Lender-update-distribution relationship with IHCDA** — parked, not urgent.
8. **Kentucky Phase 1 baseline** — not started (new item this handoff; see correction above). One Phase 3 program (UK EAHP) on file, unrelated to Phase 1 progress.

*(The "UK EAHP `designated_zone` geofencing" item from handoff #4's gap list is retired — it was based on a misreading of EAHP as a UK-country program. No such gap exists; see correction above.)*

---

## Working habits to preserve (carried forward + new this session)

- All habits from handoff #4 remain in force (cross-check source tables row-by-row before merging; surface schema-gap design decisions explicitly rather than silently picking one; re-test after every rule_config or lookup-table change; treat a wrong caveat as worse than an honest "pending" one; move `.sql` files into `HomeAccess SQL Command/` before running; keep idempotent migrations).
- **New:** curation-strategy guidance is sequencing guidance only — it never overrides a structural-design or stability decision. When the two conflict, default to raising it explicitly rather than resolving it silently in favor of curation speed.
- **New:** batch outreach-dependent confirmations across states/programs when the opportunity exists, instead of working them one at a time.
