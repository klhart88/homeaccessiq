-- Migration: Add income_threshold + financial_underwriting rules for FL Assist,
-- FL HLP, and HFA Preferred/Advantage PLUS -- pointing at NEW, currently-empty lookup
-- tables, so these three show a visible "no income limit found" caveat instead of
-- silently appearing as unconditional matches.
--
-- WHY THIS APPROACH: Florida Housing's own interactive income/purchase-price limits
-- tool (apps.floridahousing.org/StandAlone/FTHBWizard) is CURRENTLY BROKEN as of
-- 2026-07-31 (confirmed directly -- returns a server-side ASP.NET view-not-found
-- error, not a "page moved" 404). There is no static PDF equivalent to the Hometown
-- Heroes limits document for these three programs -- multiple secondary sources agree
-- the real figures live only in that tool. Rather than guess numbers or leave these
-- three with NO income check at all (which is worse -- it shows as a silent,
-- unconditional match), this migration wires up the rule structure now with empty
-- data, producing the same honest "Can't confirm yet" caveat Miami-Dade DPA had
-- before its own fix.
--
-- Per secondary-source consensus (not yet primary-source confirmed): these limits
-- reportedly (a) vary by county, (b) use a 2-tier household-size bracket (2-person-
-- or-less vs. 3-or-more, consistent with the same federal bond-compliance pattern
-- IHCDA uses), and (c) are shared across all three programs since they all pair with
-- the same Standard Bond/Standard TBA/PLUS TBA first mortgage products. One shared
-- lookup table pair is used for all three, mirroring how First Step/Step Down/Next
-- Home already share 'ihcda_first_step_income_limits'.
--
-- FOLLOW-UP NEEDED: retry apps.floridahousing.org/StandAlone/FTHBWizard once it's
-- back up, or call Florida Housing directly (850-488-4197) for the current county
-- table, then load real figures the same way the Miami-Dade fix did.

-- 1. Register the two new (empty) lookup tables
insert into geo_lookup_tables (table_name, description, value_type)
select 'fl_housing_standard_income_limits', 'Income limits for FL Assist / FL HLP / HFA Preferred-Advantage PLUS (Standard Bond/TBA/PLUS TBA programs) -- NOT YET POPULATED, source tool currently down', 'currency'
where not exists (select 1 from geo_lookup_tables where table_name = 'fl_housing_standard_income_limits');

insert into geo_lookup_tables (table_name, description, value_type)
select 'fl_housing_standard_purchase_price_limits', 'Purchase price limits for FL Assist / FL HLP / HFA Preferred-Advantage PLUS -- NOT YET POPULATED, source tool currently down', 'currency'
where not exists (select 1 from geo_lookup_tables where table_name = 'fl_housing_standard_purchase_price_limits');

-- 2. Add income_threshold rule to all three programs
insert into program_eligibility_rules (program_id, rule_type, rule_config, exempts_rule_id, evaluation_order)
select id, 'income_threshold',
       '{"comparator":"lte","income_basis":"household","lookup_table":"fl_housing_standard_income_limits"}'::jsonb,
       null, 10
from programs
where name in ('Florida Assist (FL Assist)', 'Florida Homeownership Loan Program (FL HLP)', 'HFA Preferred/Advantage PLUS Second Mortgage')
and not exists (
  select 1 from program_eligibility_rules per
  where per.program_id = programs.id and per.rule_type = 'income_threshold'
);

-- 3. Add financial_underwriting (purchase price cap) rule to all three programs
insert into program_eligibility_rules (program_id, rule_type, rule_config, exempts_rule_id, evaluation_order)
select id, 'financial_underwriting',
       '{"field":"purchase_price_cap","lookup_table":"fl_housing_standard_purchase_price_limits"}'::jsonb,
       null, 20
from programs
where name in ('Florida Assist (FL Assist)', 'Florida Homeownership Loan Program (FL HLP)', 'HFA Preferred/Advantage PLUS Second Mortgage')
and not exists (
  select 1 from program_eligibility_rules per
  where per.program_id = programs.id and per.rule_type = 'financial_underwriting'
);
