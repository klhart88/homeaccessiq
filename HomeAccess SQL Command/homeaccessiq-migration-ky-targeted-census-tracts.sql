-- ============================================================
-- Kentucky -- targeted_census_tracts population, closing the
-- last open Kentucky gap. Enables the specific 'appears to be /
-- does not appear to be' caveat message for MRB (targetedTractCaveat's
-- countyHasTractInventory / isTractListedAsTargeted), replacing
-- the generic 'no tract boundary data on file' fallback.
--
-- Same 96 tracts / 31 counties already loaded into
-- ky_khc_mrb_income_limits_targeted (8/14/26 migration) -- same
-- source document, so no new sourcing risk here, just wiring
-- the same real data into the table that produces the richer
-- message. Unlike IHCDA's tract list (2020 doc, 5 years stale
-- vs. its 2025 income data), Kentucky's tract list is the SAME
-- document as its income limits -- no currency gap to flag.
--
-- Schema confirmed via homeaccessiq-migration-ihcda-targeted-tract-
-- infrastructure.sql (table already exists from that migration --
-- this only adds KY rows, doesn't recreate the table).
-- ============================================================

insert into targeted_census_tracts (state_code, county_fips, tract_geoid, source_url, source_last_updated)
values
  ('KY', '21001', '21001970100', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21001', '21001970300', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21001', '21001970600', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21009', '21009950401', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21009', '21009950601', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21015', '21015070301', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21019', '21019030200', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21019', '21019030800', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21019', '21019031300', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21035', '21035010303', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21035', '21035010400', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21037', '21037050100', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21037', '21037050600', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21047', '21047200200', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21047', '21047200300', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21047', '21047200800', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21047', '21047201502', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21049', '21049020201', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21059', '21059000300', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21067', '21067000400', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21067', '21067001800', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21067', '21067001900', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21067', '21067002001', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21075', '21075960100', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21079', '21079970300', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21079', '21079970400', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21087', '21087930100', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21087', '21087930300', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21089', '21089040400', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21099', '21099970200', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21099', '21099970302', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21099', '21099970400', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21101', '21101020300', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21107', '21107970400', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21107', '21107970600', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21111', '21111000201', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21111', '21111000400', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21111', '21111000600', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21111', '21111000900', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21111', '21111001400', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21111', '21111001800', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21111', '21111002300', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21111', '21111002401', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21111', '21111002700', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21111', '21111003000', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21111', '21111003502', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21111', '21111003800', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21111', '21111004100', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21111', '21111004301', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21111', '21111004302', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21111', '21111005000', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21111', '21111005901', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21111', '21111005902', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21111', '21111006500', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21111', '21111011007', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21111', '21111012701', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21117', '21117065100', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21117', '21117067100', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21125', '21125970100', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21125', '21125970201', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21125', '21125970202', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21125', '21125970500', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21125', '21125971001', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21125', '21125971003', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21137', '21137920103', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21137', '21137920301', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21137', '21137920302', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21137', '21137920400', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21151', '21151010202', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21151', '21151010500', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21151', '21151010903', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21151', '21151011201', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21161', '21161960200', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21145', '21145030100', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21145', '21145030200', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21171', '21171930200', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21171', '21171930400', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21173', '21173920202', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21183', '21183920502', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21199', '21199930101', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21199', '21199930301', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21199', '21199930401', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21199', '21199930403', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21199', '21199930505', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21199', '21199930506', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21199', '21199930600', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21199', '21199930802', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21199', '21199931000', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21199', '21199931101', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21199', '21199931104', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21207', '21207960101', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21207', '21207960200', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21209', '21209040101', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21227', '21227010200', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21227', '21227010300', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23'),
  ('KY', '21227', '21227010804', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf', '2025-06-23')
on conflict (state_code, tract_geoid) do nothing;

-- Verification
select count(*) as ky_tracts_inserted from targeted_census_tracts where state_code = 'KY';

-- ------------------------------------------------------------
-- Add targeted_tract_source_url to MRB's income_threshold rule,
-- matching IHCDA's pattern (this field existed in the schema
-- and code's optional sourceNote logic, but wasn't populated
-- when the MRB program was created earlier today).
-- ------------------------------------------------------------
update program_eligibility_rules r
set rule_config = rule_config || jsonb_build_object(
  'targeted_tract_source_url', 'https://www.kyhousing.org/sites/default/files/2026-06/MRB%20Household%20Income%20Limits_0.pdf',
  'targeted_tract_data_status', 'needsVerification'
)
from programs p
where r.program_id = p.id
  and p.name = 'KHC Mortgage Revenue Bond (MRB) Program'
  and r.rule_type = 'income_threshold'
returning p.name, r.rule_config->>'targeted_tract_source_url' as source_url_now_set;