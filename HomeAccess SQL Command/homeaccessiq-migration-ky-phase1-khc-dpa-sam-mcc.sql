-- ============================================================
-- Kentucky Phase 1 baseline — KHC programs
-- Sourced 8/9/26 directly from kyhousing.org (Loan Programs,
-- Down Payment Assistance, Eligibility, SAM pages) and KHC's
-- public PowerLender rate board. See per-row source_url values.
--
-- SCOPE NOTE: this migration deliberately does NOT include KHC's
-- MRB below-market first-mortgage rate benefit (the IHCDA-Step-
-- Down analog). That program has a real first-time-buyer
-- requirement that's EXEMPTED in targeted areas (repeat buyers
-- allowed there) -- the same shape as IHCDA First Step's existing
-- targeted-area exemption. Rather than guess at how First Step's
-- live rule_config encodes that exemption, this is held back
-- pending a look at First Step's actual rule_config, so the KY
-- version replicates the same working pattern instead of
-- reinventing a possibly-inconsistent one.
--
-- Ensure Kentucky exists in the states table (likely already
-- present from UK EAHP, hence ON CONFLICT DO NOTHING rather than
-- assuming absence).
-- ============================================================

insert into states (state_code, state_name, is_active)
values ('KY', 'Kentucky', true)
on conflict (state_code) do nothing;


-- ------------------------------------------------------------
-- Geo lookup tables (metadata only -- county-level values NOT
-- populated in this migration; see note at bottom of file).
-- ------------------------------------------------------------
insert into geo_lookup_tables (id, table_name, description, value_type)
values
  ('c8a7e751-669e-4e3a-9cae-fbdc84f8ed3c', 'ky_khc_secondary_market_income_limits',
   'KHC Secondary Market program income limits, by county. Confirmed statewide range $147,350-$195,650 per kyhousing.org/page/eligibility; per-county figures not yet extracted from KHC''s income limit grid PDF.',
   'income_limit'),
  ('a62879c6-4e29-4eec-be6f-d8780a752d64', 'ky_khc_sam_income_limits',
   'KHC Shared Appreciation Mortgage (SAM) income limits, by county. Program confirmed to have income restrictions (per KHC/NKyTribune launch coverage); exact table/values not yet published or extracted -- may turn out to be the same table as Secondary Market or MRB, not yet confirmed either way.',
   'income_limit')
on conflict (table_name) do nothing;


-- ------------------------------------------------------------
-- Program 1: KHC Down Payment Assistance (DPA)
-- ------------------------------------------------------------
insert into programs (id, name, administering_entity, program_type, description, source_url, funding_status, last_verified_date)
values (
  'aa97b464-7703-4c63-9679-f55c6a827025',
  'KHC Down Payment Assistance (DPA)',
  'Kentucky Housing Corporation',
  'amortizing_loan',
  'Down payment and closing cost assistance of up to $12,500 as a secondary loan, in $100 increments, repayable over a 15-year term. Available to all KHC first-mortgage loan recipients (Conventional, FHA, VA, or RHS; Secondary Market or MRB funding), subject to purchase price and income limits, and stackable with other lender incentives when available. Carries its own interest rate, set on KHC''s lender rate sheet -- not independently published; confirm current terms with a KHC-approved lender. Note: minimum credit score depends on which KHC first-mortgage product is paired with the DPA (620 for FHA/VA/RHS, 660 for Conventional) -- not curated as a single DPA-level credit_score rule since one fixed number would misstate the requirement for at least one loan type.',
  'https://www.kyhousing.org/page/down-payment-assistance',
  'open',
  current_date
);

insert into program_eligibility_rules (id, program_id, rule_type, rule_config, evaluation_order)
values
  ('0220ad1a-88f5-4809-b731-70d300161178', 'aa97b464-7703-4c63-9679-f55c6a827025', 'geographic_scope',
   '{"scope_level": "state", "allowed_values": ["KY"]}', 0),
  ('27e79f7b-06f6-4928-8933-55a02e4cf4b9', 'aa97b464-7703-4c63-9679-f55c6a827025', 'financial_underwriting',
   '{"field": "purchase_price_cap", "comparator": "lte", "value": 566354, "note": "Sourced from kyhousing.org/page/eligibility (2026, current). A separate KHC lender PDF (SMP Income Limitations, eff. 6/23/25) states $544,232 -- likely stale/not yet updated for 2026, but flagged rather than silently resolved."}', 1),
  ('d93a3b09-2bdc-46d8-b561-436150889f6e', 'aa97b464-7703-4c63-9679-f55c6a827025', 'income_threshold',
   '{"comparator": "lte", "income_basis": "household", "geo_scope": "county", "lookup_table": "ky_khc_secondary_market_income_limits", "note": "Approximation: DPA rides on whichever first mortgage the buyer uses (Secondary Market or MRB), which have DIFFERENT income limits. This references the broader/more-common Secondary Market table; MRB-financed DPA borrowers may have a tighter real limit than this reflects. App does not currently model funding-source choice."}', 2)
;


-- ------------------------------------------------------------
-- Program 2: KHC Shared Appreciation Mortgage (SAM)
-- ------------------------------------------------------------
insert into programs (id, name, administering_entity, program_type, description, source_url, funding_status, last_verified_date)
values (
  '8bd2585a-0b9b-4170-841d-e397dd59c5ed',
  'Kentucky Shared Appreciation Mortgage (SAM)',
  'Kentucky Housing Corporation',
  'shared_appreciation_loan',
  'Zero-interest, deferred-payment second mortgage providing up to 25% of the home''s purchase price or appraised value (whichever is less) for down payment and closing costs. No payments required until the property is sold, refinanced, the first mortgage is fully paid off, or another maturity event occurs -- at which point the borrower repays the original SAM amount plus a proportional share (up to 25%) of the home''s appreciation. KHC''s first program of this kind, launched July 2026. NOTE: currently available only for newly-constructed homes -- this restriction has no matching rule_type in the current 6-type model (income_threshold / geographic_scope / occupation_membership / buyer_status / employer_criteria / financial_underwriting) and is documented here in description text only. Flagging as a real schema gap, not an oversight: a genuinely new-construction-only program can''t be filtered out for buyers targeting existing homes without either a new rule_type or a property_type field on buyer_profiles.',
  'https://www.kyhousing.org/programs/shared-appreciation-mortgage',
  'open',
  current_date
);

insert into program_eligibility_rules (id, program_id, rule_type, rule_config, evaluation_order)
values
  ('2a4cdf30-1090-44f9-a88c-ecdeba9861ad', '8bd2585a-0b9b-4170-841d-e397dd59c5ed', 'geographic_scope',
   '{"scope_level": "state", "allowed_values": ["KY"]}', 0),
  ('523cf323-1671-4716-9ad5-3327c9e8734b', '8bd2585a-0b9b-4170-841d-e397dd59c5ed', 'buyer_status',
   '{"status_required": "first_time_buyer", "lookback_years": 3}', 1),
  ('3509600e-b8fa-4167-8c7e-54b9b815ef7f', '8bd2585a-0b9b-4170-841d-e397dd59c5ed', 'financial_underwriting',
   '{"field": "purchase_price_cap", "comparator": "lte", "value": 566354, "note": "SAM-specific purchase price cap not explicitly confirmed separate from KHC''s general statewide limit -- reused here as a reasonable but unverified assumption, flagged rather than silently applied."}', 2),
  ('208e026d-566f-4f78-9d48-bf0dd199bfe1', '8bd2585a-0b9b-4170-841d-e397dd59c5ed', 'income_threshold',
   '{"comparator": "lte", "income_basis": "household", "geo_scope": "county", "lookup_table": "ky_khc_sam_income_limits", "note": "SAM is confirmed to carry income restrictions (KHC/NKyTribune launch coverage), but the specific limit table/values are not yet published or extracted."}', 3)
;


-- ------------------------------------------------------------
-- Program 3: KHC Mortgage Credit Certificate (MCC)
-- funding_status = 'exhausted' -- deliberately curated as
-- inactive-but-documented, per the schema's existing enum value,
-- so a future session doesn't re-research this from scratch.
-- fetchActivePrograms() already excludes 'exhausted' rows, so
-- this will never surface in buyer results as-is.
-- ------------------------------------------------------------
insert into programs (id, name, administering_entity, program_type, description, source_url, funding_status, last_verified_date)
values (
  '48d3d2bd-7731-45c5-8989-3745d31075bd',
  'KHC Mortgage Credit Certificate (MCC)',
  'Kentucky Housing Corporation',
  'tax_credit',
  'Federal tax credit for a portion of annual mortgage interest paid, historically up to 20-25% (rate varied by year) with a $2,000 annual cap. NOT CURRENTLY AVAILABLE: KHC confirmed program funding fully depleted as of March 18, 2024, no new applications accepted, no announced reopening date. Confirmed still inactive as of 8/9/26 -- KHC''s legacy MCC page now redirects to the general Loan Programs page, which makes no mention of MCC. Curated here with funding_status=exhausted so it stays documented and traceable rather than silently omitted; existing MCC holders from prior years are unaffected and continue claiming their credit.',
  'https://www.kyhousing.org/page/loan-programs',
  'exhausted',
  current_date
);


-- ------------------------------------------------------------
-- Verification query -- run after the inserts above
-- ------------------------------------------------------------
select p.name, p.program_type, p.funding_status, p.source_url,
       r.rule_type, r.rule_config
from programs p
left join program_eligibility_rules r on r.program_id = p.id
where p.administering_entity = 'Kentucky Housing Corporation'
order by p.name, r.evaluation_order;
