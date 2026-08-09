-- Migration: Fix AHFA Step Up income data + populate Miami-Dade DPA income limits
-- Verified 2026-07-31 against primary sources:
--   AHFA: https://www.ahfa.com/programs/homeownership/available-programs/step-up
--   Miami-Dade: https://www.miamidade.gov/global/housing/downpayment-assistance.page
--
-- ============================================================
-- PART 1: AHFA Step Up — remove fabricated two-tier structure
-- ============================================================
-- Prior data used a secondary aggregator (themortgagereports.com) with two income
-- lookup tables:
--   ahfa_step_up_income_limit       = $130,600 (stale — actual current AHFA limit is $172,800)
--   ahfa_step_up_income_limit_50pct = $65,300  (exactly half of the above — fabricated,
--                                                 not a real AHFA tier)
--
-- This was paired with two separate program_benefits rows describing a "standard tier"
-- (0.5% grant) and "higher tier" (1% grant) — both part of the same fabricated
-- income-tiering scheme. The "higher tier" row's own description even says
-- "see data-entry gap noted in rules section," confirming this was a known, flagged
-- uncertainty that was never resolved before now.
--
-- AHFA's own current site describes ONE flat benefit: 4% of sales price up to $10,000,
-- and ONE flat income limit ($172,800, no tiering). This migration removes both grant
-- tiers and the fabricated income table, and updates the real income limit table to
-- the current verified figure.

-- 1. Remove the two fabricated tiered-grant benefit rows
delete from program_benefits
where id in ('49812b4f-5709-4087-83c1-e44bae50ea96', '22212c37-2293-42db-be95-f0dc11fc3fd6');

-- 2. Remove the eligibility rule that referenced the fabricated _50pct table
--    (now safe — no longer referenced by program_benefits)
delete from program_eligibility_rules
where id = 'b54efae2-fc8f-4f22-87ba-e19ea66386dc';

-- 3. Update the real income limit table to the current verified flat figure
update geo_lookup_values
set numeric_value = 172800,
    effective_date = '2026-01-01',
    source_url = 'https://www.ahfa.com/programs/homeownership/available-programs/step-up',
    last_verified_date = '2026-07-31'
where lookup_table_id = (select id from geo_lookup_tables where table_name = 'ahfa_step_up_income_limit')
  and state_code = 'AL';

-- 4. Remove the fabricated _50pct lookup value row
delete from geo_lookup_values
where lookup_table_id = (select id from geo_lookup_tables where table_name = 'ahfa_step_up_income_limit_50pct');

-- 5. Remove the now-empty _50pct table registry entry
delete from geo_lookup_tables
where table_name = 'ahfa_step_up_income_limit_50pct';

-- Remaining AHFA Step Up benefit row (a7263fe2...) — "Base Step Up down payment
-- assistance, 4% up to $10,000, 10-year repayable second mortgage" — was left as-is;
-- it already matches AHFA's current description and needed no changes.

-- ============================================================
-- PART 2: Miami-Dade County DPA — populate previously-empty income limits
-- ============================================================
-- Prior state: geo_lookup_tables registry entry existed but had zero rows in
-- geo_lookup_values, causing every test result to show "no income limit found."
--
-- Figures below are the flat per-household-size limits stated directly in prose on
-- Miami-Dade's own program page (verified 2026-07-31). NOTE: the page links to a
-- separate "Income and Mortgage Limits" PDF for general SHIP/Surtax programs, but that
-- PDF's figures do NOT match these program-specific numbers and is NOT used here —
-- flagging that discrepancy rather than reconciling it, since the prose figures are
-- the most directly authoritative source for this specific program.
--
-- KNOWN GAP: no verified figure exists for household size 5+. The matching engine's
-- floor-based bracket logic will apply the size-4 limit to any 5+ person household,
-- which may understate their true limit. Recommend confirming with Miami-Dade PHCD
-- (Shawn Topps, 786-469-2209) before this matters for a real 5+ person applicant.

delete from geo_lookup_values
where lookup_table_id = (select id from geo_lookup_tables where table_name = 'miami_dade_county_dpa_income_limits');

insert into geo_lookup_values (lookup_table_id, state_code, county_fips, household_size, numeric_value, effective_date, source_url, last_verified_date)
values
  ((select id from geo_lookup_tables where table_name = 'miami_dade_county_dpa_income_limits'), 'FL', '12086', 1, 95620, '2026-07-31', 'https://www.miamidade.gov/global/housing/downpayment-assistance.page', '2026-07-31'),
  ((select id from geo_lookup_tables where table_name = 'miami_dade_county_dpa_income_limits'), 'FL', '12086', 2, 109200, '2026-07-31', 'https://www.miamidade.gov/global/housing/downpayment-assistance.page', '2026-07-31'),
  ((select id from geo_lookup_tables where table_name = 'miami_dade_county_dpa_income_limits'), 'FL', '12086', 3, 122920, '2026-07-31', 'https://www.miamidade.gov/global/housing/downpayment-assistance.page', '2026-07-31'),
  ((select id from geo_lookup_tables where table_name = 'miami_dade_county_dpa_income_limits'), 'FL', '12086', 4, 136500, '2026-07-31', 'https://www.miamidade.gov/global/housing/downpayment-assistance.page', '2026-07-31');
