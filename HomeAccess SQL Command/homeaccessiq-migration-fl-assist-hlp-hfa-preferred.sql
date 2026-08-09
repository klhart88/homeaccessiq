-- Migration: Add Florida Housing Finance Corporation's remaining statewide DPA programs
-- Verified 2026-07-31 directly against a full crawl of floridahousing.org
-- (homebuyer-overview-page, MCC FAQ page, Hardest Hit Fund page, Salute Our Soldiers page).
--
-- Prior to this migration, only "Florida Hometown Heroes" was loaded. Florida Housing
-- actually runs THREE additional statewide down payment assistance products, all paired
-- with a Florida Housing first mortgage (FHA/VA/USDA/Conventional, min 640 credit score,
-- IRS first-time-buyer definition, HUD-approved education required):
--
--   1. Florida Assist (FL Assist)       -- $10,000 flat, 0%, non-forgivable, deferred
--   2. FL HLP (Homeownership Loan Prog) -- $12,500 flat, 3% interest, amortizing, 30yr
--                                          (NOTE: every secondary source found earlier said
--                                          $10,000/15-year -- the real current figure per
--                                          Florida Housing's own site is $12,500/30-year)
--   3. HFA Preferred/Advantage PLUS     -- 3%, 4%, or 5% of loan amount, forgivable,
--                                          20%/year over 5 years. Only available paired
--                                          with HFA Preferred/Advantage conventional first
--                                          mortgages specifically (not FHA/VA/USDA).
--
-- IMPORTANT: Per Florida Housing's own site, these three are mutually exclusive
-- alternatives -- a buyer picks exactly one, they do not stack with each other.
-- Hometown Heroes remains a separate, independent track with its own dedicated DPA.
-- stackable_with is left as [] for all three (consistent with how Hometown Heroes is
-- already stored) -- this reflects "not stackable with the others" by omission. The
-- eligibility ENGINE does not currently enforce mutual exclusivity between programs;
-- this is documented here as a known limitation, not implemented in this migration.
--
-- NOT built in this migration, and why:
--   - Mortgage Credit Certificate (MCC): CONFIRMED RETIRED. Florida Housing's own FAQ
--     page states they have not issued MCCs since 12/31/2020. Some city/county programs
--     may still offer their own, but that's local, not statewide -- out of scope here.
--   - Hardest Hit Fund (all sub-programs): CONFIRMED CLOSED, years ago.
--   - Salute Our Soldiers Military Loan Program: AMBIGUOUS. Still listed as an active
--     "Special Program" on the current homebuyer overview page, but its own page
--     returns a 404 "has been relocated" error on Florida Housing's own site. Not
--     built here -- recommend confirming directly with Florida Housing (850-488-4197)
--     before adding. If real, it's a rate-only benefit (no DPA of its own) similar in
--     shape to IHCDA Step Down, and per secondary sources can pair with ANY of the
--     three DPA programs above (unlike them, it isn't mutually exclusive).
--
-- KNOWN GAP: county-level income limit and purchase price limit lookup tables are NOT
-- populated for these three programs (same "needs data" state Miami-Dade DPA was in
-- before its own fix). Florida Housing publishes per-county limits similar to the
-- Hometown Heroes income/loan limits PDF already linked on their site; a follow-up
-- migration should pull and load those. Until then, income_threshold and
-- financial_underwriting rules are intentionally NOT added for these three programs --
-- only the state-scope and first-time-buyer gates, which are known with confidence.

-- 1. Add the three new programs
insert into programs (name, administering_entity, program_type, description, source_url, funding_status, last_verified_date, stackable_with)
select 'Florida Assist (FL Assist)', 'Florida Housing Finance Corporation', 'deferred_loan',
       'Down payment and closing cost assistance of up to $10,000 as a 0% interest, non-amortizing, deferred second mortgage. Not forgivable -- due upon sale, transfer, satisfaction/refinance of the first mortgage, or when the home is no longer the borrower''s primary residence. Must be paired with a Florida Housing first mortgage (FHA/VA/USDA/Conventional); not available as stand-alone assistance. Not stackable with FL HLP or HFA Preferred/Advantage PLUS.',
       'https://www.floridahousing.org/programs/homebuyer-overview-page', 'open', '2026-07-31', '{}'::uuid[]
where not exists (select 1 from programs where name = 'Florida Assist (FL Assist)');

insert into programs (name, administering_entity, program_type, description, source_url, funding_status, last_verified_date, stackable_with)
select 'Florida Homeownership Loan Program (FL HLP)', 'Florida Housing Finance Corporation', 'amortizing_loan',
       'Down payment and closing cost assistance of $12,500 as a 3% interest, fully-amortizing second mortgage with a 30-year term. Carries a real monthly payment, which may need to be factored into the borrower''s DTI ratio. Remaining balance deferred until sale, transfer, satisfaction/refinance of the first mortgage, or when the home is no longer the borrower''s primary residence. Must be paired with a Florida Housing first mortgage; not stackable with FL Assist or HFA Preferred/Advantage PLUS.',
       'https://www.floridahousing.org/programs/homebuyer-overview-page', 'open', '2026-07-31', '{}'::uuid[]
where not exists (select 1 from programs where name = 'Florida Homeownership Loan Program (FL HLP)');

insert into programs (name, administering_entity, program_type, description, source_url, funding_status, last_verified_date, stackable_with)
select 'HFA Preferred/Advantage PLUS Second Mortgage', 'Florida Housing Finance Corporation', 'forgivable_loan',
       'Down payment and closing cost assistance of 3%, 4%, or 5% of the total first mortgage loan amount as a forgivable second mortgage, forgiven at 20% per year over a 5-year term, 0% interest, no monthly payment. Only available when paired with Florida Housing''s HFA Preferred or HFA Advantage conventional first mortgage products specifically (not FHA/VA/USDA). Not stackable with FL Assist or FL HLP.',
       'https://www.floridahousing.org/programs/homebuyer-overview-page', 'open', '2026-07-31', '{}'::uuid[]
where not exists (select 1 from programs where name = 'HFA Preferred/Advantage PLUS Second Mortgage');

-- 2. Add benefit rows for each
insert into program_benefits (program_id, linked_rule_id, benefit_type, amount_type, amount_value, max_amount, description)
select id, null, 'deferred_loan', 'flat_amount', 10000, 10000, 'Flat $10,000 deferred second mortgage, 0% interest, non-forgivable'
from programs where name = 'Florida Assist (FL Assist)'
and not exists (select 1 from program_benefits where program_id = programs.id);

insert into program_benefits (program_id, linked_rule_id, benefit_type, amount_type, amount_value, max_amount, description)
select id, null, 'amortizing_loan', 'flat_amount', 12500, 12500, 'Flat $12,500 second mortgage, 3% interest, fully amortizing over 30 years, real monthly payment (~$69/mo)'
from programs where name = 'Florida Homeownership Loan Program (FL HLP)'
and not exists (select 1 from program_benefits where program_id = programs.id);

insert into program_benefits (program_id, linked_rule_id, benefit_type, amount_type, amount_value, max_amount, description)
select id, null, 'forgivable_loan', 'percent_of_purchase_price', 5, null, '3%, 4%, or 5% of first mortgage loan amount (tier depends on specific HFA product used), forgivable 20%/year over 5 years'
from programs where name = 'HFA Preferred/Advantage PLUS Second Mortgage'
and not exists (select 1 from program_benefits where program_id = programs.id);

-- 3. Add state-scope (FL only) and first-time-buyer eligibility rules for each
--    (income_threshold / financial_underwriting deliberately NOT added yet -- see
--    KNOWN GAP note above)
insert into program_eligibility_rules (program_id, rule_type, rule_config, exempts_rule_id, evaluation_order)
select id, 'geographic_scope', '{"scope_level":"state","allowed_values":["FL"]}'::jsonb, null, -10
from programs where name = 'Florida Assist (FL Assist)'
and not exists (select 1 from program_eligibility_rules per where per.program_id = programs.id and per.rule_type = 'geographic_scope');

insert into program_eligibility_rules (program_id, rule_type, rule_config, exempts_rule_id, evaluation_order)
select id, 'buyer_status', '{"lookback_years":3,"status_required":"first_time_buyer"}'::jsonb, null, 0
from programs where name = 'Florida Assist (FL Assist)'
and not exists (select 1 from program_eligibility_rules per where per.program_id = programs.id and per.rule_type = 'buyer_status');

insert into program_eligibility_rules (program_id, rule_type, rule_config, exempts_rule_id, evaluation_order)
select id, 'geographic_scope', '{"scope_level":"state","allowed_values":["FL"]}'::jsonb, null, -10
from programs where name = 'Florida Homeownership Loan Program (FL HLP)'
and not exists (select 1 from program_eligibility_rules per where per.program_id = programs.id and per.rule_type = 'geographic_scope');

insert into program_eligibility_rules (program_id, rule_type, rule_config, exempts_rule_id, evaluation_order)
select id, 'buyer_status', '{"lookback_years":3,"status_required":"first_time_buyer"}'::jsonb, null, 0
from programs where name = 'Florida Homeownership Loan Program (FL HLP)'
and not exists (select 1 from program_eligibility_rules per where per.program_id = programs.id and per.rule_type = 'buyer_status');

insert into program_eligibility_rules (program_id, rule_type, rule_config, exempts_rule_id, evaluation_order)
select id, 'geographic_scope', '{"scope_level":"state","allowed_values":["FL"]}'::jsonb, null, -10
from programs where name = 'HFA Preferred/Advantage PLUS Second Mortgage'
and not exists (select 1 from program_eligibility_rules per where per.program_id = programs.id and per.rule_type = 'geographic_scope');

insert into program_eligibility_rules (program_id, rule_type, rule_config, exempts_rule_id, evaluation_order)
select id, 'buyer_status', '{"lookback_years":3,"status_required":"first_time_buyer"}'::jsonb, null, 0
from programs where name = 'HFA Preferred/Advantage PLUS Second Mortgage'
and not exists (select 1 from program_eligibility_rules per where per.program_id = programs.id and per.rule_type = 'buyer_status');

-- 4. Bonus fix: Hometown Heroes' source_url currently points to a secondary aggregator
--    (makefloridayourhome.com) rather than Florida Housing's own site. Correcting it
--    now that the real official page is confirmed.
update programs
set source_url = 'https://www.floridahousing.org/live-local-act/hometown-heroes-program',
    last_verified_date = '2026-07-31'
where name = 'Florida Hometown Heroes';
